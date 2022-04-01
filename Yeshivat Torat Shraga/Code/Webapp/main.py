from datetime import datetime, timedelta
from fileinput import filename
from flask import Flask, Response, redirect, render_template, request, url_for, flash
from flask_basicauth import BasicAuth
import ffmpeg
import os
import settings

from firebase_admin import credentials, initialize_app, storage, firestore, messaging

# Check if the following environment variables are set:
username = settings.username
password = settings.password
cred = settings.cred

# Dump the credentials to the file variable
with open("cred.json", "w") as f:
    f.write(cred)

cred = credentials.Certificate("cred.json")
initialize_app(cred, {"storageBucket": "yeshivat-torat-shraga.appspot.com"})

app = Flask(__name__)
basic_auth = BasicAuth(app)

app.config["BASIC_AUTH_USERNAME"] = settings.username
app.config["BASIC_AUTH_PASSWORD"] = settings.password
app.config["BASIC_AUTH_FORCE"] = True


@app.route("/")
def index():
    return render_template("home.html")


# healtcheck return 200
@app.route("/healthcheck")
def healthcheck():
    return Response(status=200)


@app.route("/notifications/alert", methods=["POST"])
def alert_notification():
    db = firestore.client()
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
    message = messaging.Message(
        notification=messaging.Notification(
            title=request.form.get("push-title"),
            body=request.form.get("push-body"),
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    # badge=int(request.form.get("badge-count", 0))
                ),
            ),
        ),
        topic="all",
    )

    messaging.send(message)
    flash("Notification sent!")
    return redirect(url_for("notifications"))


@app.route("/notifications", methods=["GET"])
def notifications():
    return render_template("notifications.html")


@app.route("/rabbis", methods=["GET"])
def rabbis():
    db = firestore.client()
    bucket = storage.bucket()
    collection = []
    for rabbi in db.collection("rebbeim").get():
        id = rabbi.id
        rabbi = rabbi.to_dict()
        rabbi["id"] = id
        blob = bucket.get_blob(f"profile-pictures/{rabbi['profile_picture_filename']}")
        url = blob.generate_signed_url(timedelta(seconds=300))
        rabbi["imgURL"] = url
        collection.append(rabbi)

    return render_template("rabbis.html", data=collection)


@app.route("/rabbis/<ID>", methods=["GET", "POST"])
def rabbiDetail(ID):
    db = firestore.client()
    bucket = storage.bucket()
    if request.method == "GET":
        rabbi = db.collection("rebbeim").document(ID).get().to_dict()
        rabbi["id"] = ID
        blob = bucket.get_blob(f"profile-pictures/{rabbi['profile_picture_filename']}")
        url = blob.generate_signed_url(timedelta(seconds=300))
        rabbi["imgURL"] = url

        return render_template("rabbisdetail.html", rabbi=rabbi, new=False)
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
        return redirect(url_for("rabbis"))


@app.route("/rabbis/delete/<ID>", methods=["POST"])
def rabbiDelete(ID):
    db = firestore.client()
    rabbi = db.collection("rebbeim").document(ID)
    rabbi.delete()
    return redirect(url_for("rabbis"))


@app.route("/rabbis/create", methods=["GET", "POST"])
def rabbiCreate():
    if request.method == "GET":
        return render_template("rabbisdetail.html", rabbi=None, new=True)
    else:
        # Upload the profile picture file from the form to Cloud Storage
        profile_picture_file = request.files["file"]
        if not profile_picture_file:
            return "No profile picture", 400
        bucket = storage.bucket()
        blob = bucket.blob(f"profile-pictures/{profile_picture_file.filename}")
        blob.upload_from_string(
            profile_picture_file.read(), content_type=profile_picture_file.content_type
        )

        db = firestore.client()
        collection = db.collection("rebbeim")
        collection.add(
            {
                "name": request.form.get("name"),
                "profile_picture_filename": profile_picture_file.filename,
            }
        )
        flash("Rabbi added!")
        return redirect(url_for("rabbis"))


@app.route("/shiurim/", methods=["GET"])
def shiurim():
    db = firestore.client()
    collection = []
    for shiur in db.collection("content").get():
        id = shiur.id
        shiur = shiur.to_dict()
        shiur["id"] = id
        collection.append(shiur)
    # Sort collection by date
    collection.sort(key=lambda x: x["date"], reverse=True)
    return render_template("shiurim.html", data=collection)


@app.route("/shiurim/<ID>", methods=["GET", "POST"])
def shiurimDetail(ID):
    db = firestore.client()
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
            "shiurimdetail.html", shiur=collection, rabbis=rabbis, ID=ID
        )
    else:
        # Update the shiur document

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
    db = firestore.client()
    shiur = db.collection("content").document(ID)
    shiur.delete()
    return redirect(url_for("shiurim"))


@app.route("/shiurim/upload", methods=["GET", "POST"])
def shiurim_upload():
    db = firestore.client()
    rebbeim_collection = db.collection("rebbeim")
    tags_collection = db.collection("tags")
    tag_docs = tags_collection.list_documents()
    tags = []
    for tag in tag_docs:
        tag = tag.get()
        tag_dict = tag.to_dict()
        tag_dict["id"] = tag.id
        tags.append(tag_dict)
    if request.method == "GET":
        rebbeim_docs = rebbeim_collection.list_documents()
        rabbis = []
        for doc in rebbeim_docs:
            doc = doc.get()
            doc_dict = doc.to_dict()
            doc_dict["id"] = doc.id
            rabbis.append(doc_dict)
        return render_template(
            "shiur_upload.html", rabbis=rabbis, type="Shiurim", tags=tags
        )
    else:
        # try:
        rabbi = request.form.get("author").split("~")
        file = request.files["file"]
        date = datetime.strptime(
            request.form.get(
                "date", datetime.strftime(datetime.now(), "%Y-%m-%d %H:%M:%S")
            ),
            "%Y-%m-%d %H:%M:%S",
        )
        file.filename = (
            datetime.strftime(datetime.now(), "%d%m%Y%H%M%S%f")
            + "."
            + file.filename.split(".")[-1]
        )

        attributionID = rabbi[0]
        author = rabbi[1]
        description = request.form.get("description", "")

        # create tmp folder if it doesn't exist
        if not os.path.exists("tmp"):
            os.makedirs("tmp")
        file.save("tmp/" + file.filename)
        duration = ffmpeg.probe("tmp/" + file.filename)["format"]["duration"]
        duration = int(float(duration))

        # Title:
        title = request.form.get("title", "")

        # Content Type:
        content_type = request.form.get("type", "")

        # Source Path:
        #   Based on the file type, decide on the source path.
        #   Part of this process will be to give the file a
        #   unique name based on the rabbi's name and the date.
        #   We first need to strip the file extension.
        # get second to last element of file name
        filename_components = file.filename.split(".")
        stripped_name = ""
        if len(filename_components) > 1:
            stripped_name = filename_components[-2]
        else:
            stripped_name = filename_components[0]
        source_path = f"HLSStreams/{content_type}/{stripped_name}/{stripped_name}.m3u8"

        # Tags:
        selected_tags = request.form.get("tags", "").split(",")
        # lowercase the entire list
        full_tags = []
        [
            full_tags.append({"name": tag.lower(), "fullname": tag})
            for tag in selected_tags
        ]
        # - For each tag, check if it exists in the tags collection,
        #   if it doesn't, create it.
        for tag in selected_tags:
            if tag not in [tag["name"] for tag in tags]:
                tags_collection.add({"name": tag})

        # Search Index:
        #   Decide on a formulae for creating the search indices
        search_index = [word.lower() for word in title.split(" ")]
        [search_index.append(tag) for tag in selected_tags]

        new_content_document = {
            "attributionID": attributionID,
            "author": author,
            "date": date,
            "description": description,
            "duration": duration,
            "search_index": search_index,
            "source_path": source_path,
            "tags": selected_tags,
            "title": title,
            "type": content_type,
        }
        content_collection = db.collection("content")
        content_collection.add(new_content_document)
        bucket = storage.bucket()
        blob = bucket.blob(f"content/{file.filename}")
        blob.upload_from_filename("tmp/" + file.filename)
        flash("Shiur added!")
        collection = [
            (shuir.to_dict(), shuir.id) for shuir in db.collection("content").get()
        ]
        # delete everything in tmp folder
        for tmpfile in os.listdir("tmp"):
            os.remove("tmp/" + tmpfile)
        os.rmdir("tmp")
        return render_template("shiurim.html", data=collection)


@app.route("/news", methods=["GET"])
def news():
    db = firestore.client()
    collection = [(rabbi.to_dict(), rabbi.id) for rabbi in db.collection("news").get()]
    return render_template("news.html", news=collection)


@app.route("/news/<ID>", methods=["GET", "POST"])
def news_detail(ID):
    db = firestore.client()
    if request.method == "GET":
        article = db.collection("news").document(ID).get().to_dict()
        article["id"] = ID
        return render_template("newsdetail.html", article=article)
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

        document = db.collection("news").document(ID)
        document.update(updated_document)
        return redirect(url_for("news"))


@app.route("/news/delete/<ID>", methods=["POST"])
def news_delete(ID):
    db = firestore.client()
    article = db.collection("news").document(ID)
    article.delete()
    return redirect(url_for("news"))


@app.route("/news/create", methods=["GET", "POST"])
def news_create():
    db = firestore.client()
    if request.method == "GET":
        return render_template("newsdetail.html", article=None)
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
        return redirect(url_for("news"))


@app.route("/slideshow", methods=["GET"])
def slideshow():
    bucket = storage.bucket()
    db = firestore.client()
    if request.method == "GET":
        collection = [
            (slide.to_dict(), slide.id)
            for slide in db.collection("slideshowImages").get()
        ]
        for slide in collection:
            blob = bucket.get_blob(f"slideshow/{slide[0]['image_name']}")
            url = blob.generate_signed_url(timedelta(seconds=300))
            slide[0]["url"] = url
        return render_template("slideshow.html", images=collection)


@app.route("/slideshow/delete/<ID>", methods=["POST"])
def slideshow_delete(ID):
    db = firestore.client()
    slide = db.collection("slideshowImages").document(ID)
    slide.delete()
    return redirect(url_for("slideshow"))


@app.route("/slideshow/create", methods=["GET", "POST"])
def slideshow_upload():
    if request.method == "GET":
        return render_template("slideshowdetail.html")
    else:
        db = firestore.client()
        bucket = storage.bucket()
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
            blob.upload_from_string(file.read(), content_type=file.content_type)

        return redirect(url_for("slideshow"))


if __name__ == "__main__":
    app.secret_key = "super secret key"
    app.run(debug=True, host="localhost", port=8080)
