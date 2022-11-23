from datetime import datetime, timedelta
from fileinput import filename
from flask import Flask, Response, redirect, render_template, request, send_from_directory, url_for, flash
from flask_basicauth import BasicAuth
import ffmpeg
import os
import settings
from firebase_admin import credentials, initialize_app, storage, firestore, messaging
from blake3 import blake3
from google.cloud.exceptions import NotFound
import hashlib
from uuid import uuid4
import threading

PRODUCTION = os.getenv("PRODUCTION")

# Check if the following environment variables are set:
username = settings.username
password = settings.password

cred = credentials.Certificate("cred.json")
initialize_app(cred, {"storageBucket": "yeshivat-torat-shraga.appspot.com"})
notification_topic = "debug"

app = Flask(__name__)
if PRODUCTION:
    basic_auth = BasicAuth(app)
    notification_topic = "all"


app.config["BASIC_AUTH_USERNAME"] = settings.username
app.config["BASIC_AUTH_PASSWORD"] = settings.password
app.config["BASIC_AUTH_FORCE"] = True
db = firestore.client()
bucket = storage.bucket()
cached_rebbeim = []
cached_tags = []

def delete_folder(bucket, folder_name):
#     bucket = cls.storage_client.get_bucket(bucket_name)
#     """Delete object under folder"""
    blobs = list(bucket.list_blobs(prefix=folder_name))
    # flash(blobs)
    delete_thread = threading.Thread(target=bucket.delete_blobs, name="DeleteFolder", args=(blobs))
    delete_thread.start()
    print(f"Folder {folder_name} deleting.")
    return

def delete_file(bucket, filepath):
    delete_thread = threading.Thread(target=bucket.delete_blob, name="DeleteFile", args=(filepath))
    delete_thread.start()
    
def send_push_notification(title, body, badge):
    if title is None and body is None and badge is None:
        print("No notification sent")
        return
    if title is None and body is None:
        message = messaging.Message(
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        content_available=True,
                    )
                ),
            ),
            data={"badge": str(badge)},
        )
    else:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        mutable_content=True,
                        badge=badge
                    )
                )
            )
        )
    message.topic = notification_topic
    messaging.send(message)
    flash("Notification sent")


def send_personal_notification(fcmToken, title, body, should_increment_badge=True):
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    mutable_content=True,
                    badge=1 if should_increment_badge else None
                )
            )
        ),
        token=fcmToken
    )
    messaging.send(message)


def silent_badge_increment(badge=1):
    send_push_notification(None, None, badge)


@app.route("/refresh_cache")
def refresh_cache():
    print("Refreshing cache")
    global cached_rebbeim
    global cached_tags
    cached_rebbeim = []
    cached_tags = []
    for rabbi in db.collection("rebbeim").get():
        id = rabbi.id
        rabbi = rabbi.to_dict()
        rabbi["id"] = id
        blob = bucket.get_blob(
            f"profile-pictures/{rabbi['profile_picture_filename']}")
        url = blob.generate_signed_url(timedelta(seconds=60 * 60))
        rabbi["imgURL"] = url
        cached_rebbeim.append(rabbi)
    for tag in db.collection("tags").get():
        id = tag.id
        tag = tag.to_dict()
        tag["id"] = id
        cached_tags.append(tag)
    cached_rebbeim.sort(key=lambda x: x["name"])
    cached_tags.sort(key=lambda x: x["displayName"])
    return redirect(url_for("index"))


@app.route("/")
def index():
    if len(cached_rebbeim) == 0:
        refresh_cache()
    return render_template("home.html")


@app.route('/favicon.ico')
def favicon():
    return send_from_directory(os.path.join(app.root_path, 'static'), 'favicon.ico', mimetype='image/vnd.microsoft.icon')


@app.route("/healthcheck")
def healthcheck():
    return Response(status=200)


@app.route("/notifications/alert", methods=["POST"])
def alert_notification():
    if len(cached_rebbeim) == 0:
        refresh_cache()
    collection = db.collection("alerts")
    collection.add(
        {
            "body": request.form.get("alert-body", ""),
            "title": request.form.get("alert-title", "Notice"),
            "dateIssued": datetime.now(),
            "dateExpired": datetime.now() + timedelta(days=7),
        }
    )
    flash("Alert sent!")
    return redirect(url_for("notifications"))


@app.route("/notifications/push", methods=["POST"])
def push_notification():
    title = request.form.get("push-title")
    body = request.form.get("push-body")
    send_push_notification(title, body, 1)
    return redirect(url_for("notifications"))


@app.route("/notifications", methods=["GET"])
def notifications():
    if len(cached_rebbeim) == 0:
        refresh_cache()
    return render_template("notifications.html", type="Notifications")


@app.route("/rabbis", methods=["GET"])
def rabbis():
    if len(cached_rebbeim) == 0:
        refresh_cache()
    return render_template("rabbis.html", data=cached_rebbeim, type="Rebbi")


@app.route("/rabbis/<ID>", methods=["GET", "POST"])
def rabbiDetail(ID):
    if len(cached_rebbeim) == 0:
        refresh_cache()
    if request.method == "GET":
        rabbi = db.collection("rebbeim").document(ID).get().to_dict()
        rabbi["id"] = ID
        blob = bucket.get_blob(
            f"profile-pictures/{rabbi['profile_picture_filename']}")
        url = blob.generate_signed_url(timedelta(seconds=300))
        rabbi["imgURL"] = url

        return render_template("rabbisdetail.html", rabbi=rabbi, new=False, type="Rebbi")
    else:
        file = request.files.get("file")
        name = request.form.get("name")
        updated_document = {"name": name}
        if file:
            blob = bucket.blob(f"profile-pictures/{file.filename}")
            blob.upload_from_string(
                request.files["file"].read(),
                content_type=request.files["file"].content_type,
            )
            updated_document["profile_picture_filename"] = file.filename
        rabbi = db.collection("rebbeim").document(ID)
        rabbi.update(updated_document)
        flash("Rabbi updated!")
        refresh_cache()
        return redirect(url_for("rabbis"))


@app.route("/rabbis/delete/<ID>", methods=["POST"])
def rabbiDelete(ID):
    if len(cached_rebbeim) == 0:
        refresh_cache()
    rabbi = db.collection("rebbeim").document(ID)
    pp_filename = (rabbi.get().to_dict())["profile_picture_filename"]
    pp_filepath = f"profile-pictures/{pp_filename}"
    delete_file(bucket, pp_filepath)


    # vulnerability here, if the deletion fails it will still remove the document
    rabbi.delete()
    flash("The profile was successfully deleted.")

    refresh_cache()
    return redirect(url_for("rabbis"))


@app.route("/rabbis/create", methods=["GET", "POST"])
def rabbiCreate():
    if len(cached_rebbeim) == 0:
        refresh_cache()
    if request.method == "GET":
        return render_template("rabbisdetail.html", rabbi=None, new=True, type="Rebbi")
    else:
        # Upload the profile picture file from the form to Cloud Storage
        profile_picture_file = request.files["file"]
        if not profile_picture_file:
            return "No profile picture", 400
        blob = bucket.blob(f"profile-pictures/{profile_picture_file.filename}")
        blob.upload_from_string(
            profile_picture_file.read(), content_type=profile_picture_file.content_type
        )

        collection = db.collection("rebbeim")
        name = request.form.get("name").strip()
        collection.add(
            {
                "name": name,
                "profile_picture_filename": profile_picture_file.filename
            }
        )
        flash("Rabbi added!")
        refresh_cache()
        return redirect(url_for("rabbis"))


@app.route("/shiurim", methods=["GET"])
def shiurim():
    if len(cached_rebbeim) == 0:
        refresh_cache()
    collection = []
    for shiur in db.collection('content').order_by("date", direction="DESCENDING").where("pending", "==", False).get():
        id = shiur.id
        shiur = shiur.to_dict()
        shiur["id"] = id
        collection.append(shiur)
    # Sort collection by date
    collection.sort(key=lambda x: x["date"], reverse=True)
    return render_template("shiurim.html", data=collection, type="Shiurim")


@app.route("/shiurim/pending", methods=["GET"])
def shiurim_pending_list():
    if len(cached_rebbeim) == 0:
        refresh_cache()
    collection = []
    for shiur in db.collection('content').order_by("date", direction="DESCENDING").where("pending", "==", True).get():
        id = shiur.id
        shiur = shiur.to_dict()
        shiur["id"] = id
        collection.append(shiur)
    if len(collection) == 0:
        flash("There are no pending shiurim.")
    # Sort collection by date
    collection.sort(key=lambda x: x["date"], reverse=True)
    return render_template("pending_shiurim.html", data=collection, type="Shiurim")


@app.route("/shiurim/pending/<ID>", methods=["GET", "POST"])
def shiur_review(ID):
    if request.method == "GET":
        if len(cached_rebbeim) == 0:
            refresh_cache()
        shiur = db.collection('content').document(ID).get().to_dict()
        shiur["id"] = ID
        shiur["date"] = shiur["date"].date()
        # Get a signed URL for the file
        blob = bucket.blob(shiur['source_path'])
        url = blob.generate_signed_url(timedelta(seconds=300))
        shiur["contentLink"] = url
        return render_template("shiur_review.html", shiur=shiur, tags=cached_tags, rabbis=cached_rebbeim, type="Shiur Review")
    elif request.method == "POST":
        approval_status = request.form.get(
            "approval_status", "denied", type=str)
        if approval_status == "approved":

            rabbi = request.form.get("author").split("~")
            date = datetime.strptime(
                request.form.get(
                    "date", datetime.strftime(
                        datetime.now(), "%Y-%m-%d %H:%M:%S")
                ),
                "%Y-%m-%d %H:%M:%S",
            )
            attributionID = rabbi[0]
            author = rabbi[1]

            # create tmp folder if it doesn't exist
            # Title:
            title = request.form.get("title", "")

            # Tags:
            # Default to MISC.
            selected_tag_ID = request.form.get("tag", "NKwXl5QXmOe6rlQ9J3kW")

            # Get the tag document from the tag ID.
            selected_tag = [tag for tag in cached_tags if tag["id"]
                            == selected_tag_ID][0]
            tag_data = {
                "name": selected_tag["name"],
                "displayName": selected_tag["displayName"],
                "id": selected_tag["id"],
            }

            updated_document = {
                "attributionID": attributionID,
                "author": author,
                "date": date,
                "tagData": tag_data,
                "title": title,
                "pending": False
            }

            shiur = db.collection('content').document(ID)
            shiur.update(updated_document)
            flash("Shiur approved!")
            # Send a APNS notification that badges the app
            if "upload_data" in shiur.get().to_dict():
                upload_data = shiur["upload_data"]
                if "token" in upload_data:
                    token = upload_data["token"]
                    send_personal_notification(
                        token, "Your shiur has been approved!", "It will be available in the app shortly.")
            silent_badge_increment()
            return redirect(url_for("shiurim_pending_list"))
        elif approval_status == "denied":
            shiur = db.collection('content').document(ID)
            shiur_data = shiur.get().to_dict()
            source_path = shiur_data["source_path"]
            content_type = shiur_data["type"]
            file_hash = source_path.split("/")[2]
            try:
                delete_folder(bucket, f"HLSStreams/{content_type}/{file_hash}")
                # vulnerability here, if the deletion fails it will still remove the document
                shiur.delete()
                flash("The shiur was successfully denied is being deleted.")
            except NotFound:
                flash("The shiur content files could not be found.")
                pass
            except Exception as e:
                flash(str(e.message))
            return redirect(url_for("shiurim_pending_list"))


@app.route("/shiurim/<ID>", methods=["GET", "POST"])
def shiurimDetail(ID):
    if len(cached_rebbeim) == 0:
        refresh_cache()
    if request.method == "GET":
        collection = db.collection("content").document(ID).get().to_dict()
        rabbis = []
        rabbicollection = db.collection("rebbeim")
        documents = rabbicollection.list_documents()
        for doc in documents:
            doc = doc.get()
            doc_dict = doc.to_dict()
            doc_dict["id"] = doc.id
            rabbis.append(doc_dict)
        return render_template(
            "shiurimdetail.html", shiur=collection, rabbis=rabbis, ID=ID, type="Shiurim"
        )
    else:
        # Update the document

        updated_document = {}
        author = request.form.get("author").split("~")
        author = author[1]
        title = request.form.get("title")
        updated_document["title"] = title
        updated_document["author"] = author

        document = db.collection("content").document(ID)
        document.update(updated_document)
        return redirect(url_for("shiurim"))


@app.route("/shiurim/delete/<ID>", methods=["POST"])
def shiurim_delete(ID):
    if len(cached_rebbeim) == 0:
        refresh_cache()
    shiur = db.collection("content").document(ID)
    shiur_data = shiur.get().to_dict()
    source_path = shiur_data["source_path"]
    content_type = shiur_data["type"]
    file_hash = source_path.split("/")[2]
    try:
        delete_folder(bucket, f"HLSStreams/{content_type}/{file_hash}")
        # vulnerability here, if the deletion fails it will still remove the document
        shiur.delete()
        flash("The shiur is being deleted.")
    except NotFound as e:
        flash("The shiur content files could not be found.")
        pass
    return redirect(url_for("shiurim"))


@app.route("/shiurim/upload", methods=["GET", "POST"])
def shiurim_upload():
    if len(cached_rebbeim) == 0:
        refresh_cache()
    if request.method == "GET":
        # sort by name
        cached_rebbeim.sort(key=lambda x: x["name"])
        return render_template(
            "shiur_upload.html", rabbis=cached_rebbeim, type="Shiurim", tags=cached_tags
        )
    else:
        file = request.files["file"]
        if "audio" not in file.content_type and "video" not in file.content_type:
            flash("You must upload an audio or video file.")
            return redirect(url_for("shiurim_upload"))
        # set the filename to a UUID for security
        secure_random_filename = str(uuid4())
        # try:
        rabbi = request.form.get("author").split("~")
        date = datetime.strptime(
            request.form.get(
                "date", datetime.strftime(datetime.now(), "%Y-%m-%d %H:%M:%S")
            ),
            "%Y-%m-%d %H:%M:%S",
        )

        attributionID = rabbi[0]
        author = rabbi[1]
        description = request.form.get("description", "")

        # create tmp folder if it doesn't exist
        if not os.path.exists("tmp"):
            os.makedirs("tmp")

        file.save("tmp/" + secure_random_filename)
        # Calculate the MD5 hash of the file
        file_hash = hashlib.sha256(
            open("tmp/" + secure_random_filename, "rb").read()).hexdigest()
        duration = ffmpeg.probe(
            "tmp/" + secure_random_filename)["format"]["duration"]
        duration = int(float(duration))

        # Title:
        title = request.form.get("title", "")

        # Content Type:
        content_type = request.form.get("type", "")

        source_path = f"HLSStreams/audio/{file_hash}/{file_hash}.m3u8"

        # Tags:
        # Default to MISC.
        selected_tag_ID = request.form.get("tag", "NKwXl5QXmOe6rlQ9J3kW")

        # Get the tag document from the tag ID.
        selected_tag = [tag for tag in cached_tags if tag["id"]
                        == selected_tag_ID][0]
        tag_data = {
            "name": selected_tag["name"],
            "displayName": selected_tag["displayName"],
            "id": selected_tag["id"],
        }

        # Search Index:
        #   Decide on a formulae for creating the search indices
#        search_index = [word.lower() for word in title.split(" ")]
#        search_index.extend([word.lower()
#                            for word in selected_tag["displayName"].split(" ")])
#        search_index.extend([word.lower()
#                            for word in author.split(" ") if word != "rabbi"])

        new_content_document = {
            "attributionID": attributionID,
            "author": author,
            "date": date,
            "description": description,
            "duration": duration,
            "source_path": source_path,
            "tagData": tag_data,
            "title": title,
            "type": content_type,
            "pending": False
        }

        content_collection = db.collection("content")
        content_collection.add(new_content_document)
        blob = bucket.blob(f"content/{file_hash}")
        blob.upload_from_filename("tmp/" + secure_random_filename)
        # delete everything in tmp folder
        for tmpfile in os.listdir("tmp"):
            os.remove("tmp/" + tmpfile)
        os.rmdir("tmp")
        silent_badge_increment()
        return redirect(url_for("shiurim"))


@app.route("/news", methods=["GET"])
def news():
    if len(cached_rebbeim) == 0:
        refresh_cache()
    collection = []
    for article in db.collection("news").get():
        id = article.id
        article = article.to_dict()
        article["id"] = id
        collection.append(article)
    # Sort collection by date
    collection.sort(key=lambda x: x["date"], reverse=True)
    return render_template("news.html", news=collection, type="News")


@app.route("/news/<ID>", methods=["GET", "POST"])
def news_detail(ID):
    if len(cached_rebbeim) == 0:
        refresh_cache()
    if request.method == "GET":
        article = db.collection("news").document(ID).get().to_dict()
        article["id"] = ID
        return render_template("newsdetail.html", article=article, type="News")
    else:
        # Update the shiur document

        updated_document = {}
        author = request.form.get("author")
        title = request.form.get("title")
        body = request.form.get("body")
        updated_document["title"] = title
        updated_document["author"] = author
        updated_document["body"] = body
        updated_document["date"] = datetime.now()

        # document = db.collection("news").document(ID)
        # document.update(updated_document)
        should_badge_app = (request.form.get("send_badge", "off") == "on")
        if should_badge_app:
            silent_badge_increment()
        return redirect(url_for("news"))


@app.route("/news/delete/<ID>", methods=["POST"])
def news_delete(ID):
    if len(cached_rebbeim) == 0:
        refresh_cache()
    article = db.collection("news").document(ID)
    article.delete()
    return redirect(url_for("news"))


@app.route("/news/create", methods=["GET", "POST"])
def news_create():
    if len(cached_rebbeim) == 0:
        refresh_cache()
    if request.method == "GET":
        return render_template("newsdetail.html", article=None, type="News")
    else:
        author = request.form.get("author")
        title = request.form.get("title")
        body = request.form.get("body")
        date = datetime.now()
        new_document = {
            "author": author,
            "title": title,
            "body": body,
            "date": date,
            "imageURLs": [""],
        }
        db.collection("news").add(new_document)
        silent_badge_increment()
        return redirect(url_for("news"))


@app.route("/slideshow", methods=["GET"])
def slideshow():
    if len(cached_rebbeim) == 0:
        refresh_cache()
    collection = []
    for article in db.collection("slideshowImages").get():
        id = article.id
        article = article.to_dict()
        article["id"] = id
        collection.append(article)
    # Sort collection by date
    collection.sort(key=lambda x: x["uploaded"], reverse=True)

    for slide in collection:
        blob = bucket.get_blob(f"slideshow/{slide['image_name']}")
        url = blob.generate_signed_url(timedelta(seconds=300))
        slide["url"] = url
    return render_template("slideshow.html", images=collection, type="Slideshow")


@app.route("/slideshow/delete/<ID>", methods=["POST"])
def slideshow_delete(ID):
    if len(cached_rebbeim) == 0:
        refresh_cache()
    slide = db.collection("slideshowImages").document(ID)
    slide_data = slide.get().to_dict()
    slide_filename = slide_data["image_name"]
    slide_filepath = f"slideshow/{slide_filename}"
    delete_file(bucket, slide_filepath)

    # vulnerability here, if the deletion fails it will still remove the document
    slide.delete()
    return redirect(url_for("slideshow"))


@app.route("/slideshow/create", methods=["GET", "POST"])
def slideshow_upload():
    if len(cached_rebbeim) == 0:
        refresh_cache()
    if request.method == "GET":
        return render_template("slideshowdetail.html", type="Slideshow")
    else:
        files = request.files.getlist("file")

        for file in files:
            if file.filename == files[0].filename:
                title = request.form.get("title")
            else:
                title = None
            image_url = file.filename
            new_document = {
                "title": title,
                "image_name": image_url,
                "uploaded": datetime.now(),
            }
            db.collection("slideshowImages").add(new_document)
            blob = bucket.blob(f"slideshow/{file.filename}")
            blob.upload_from_string(
                file.read(), content_type=file.content_type)

        return redirect(url_for("slideshow"))

if __name__ == "__main__":
    app.secret_key = "super secret key"
    if PRODUCTION:
        print("Running in production mode")
        app.run(debug=False, host="0.0.0.0", port=80)
    else:
        print("Running in development mode")
        app.run(debug=True, host="localhost", port=8080)
      
