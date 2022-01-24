from datetime import datetime
from flask import Flask, redirect, render_template, request, url_for
from flask_basicauth import BasicAuth
import cv2

# import settings
from firebase_admin import credentials, initialize_app, storage, firestore

cred = credentials.Certificate("cred.json")
initialize_app(cred, {"storageBucket": "yeshivat-torat-shraga.appspot.com"})

app = Flask(__name__)
# basic_auth = BasicAuth(app)

# app.config["BASIC_AUTH_USERNAME"] = "username"  # settings.username
# app.config["BASIC_AUTH_PASSWORD"] = ""  # settings.password
# app.config["BASIC_AUTH_FORCE"] = True


@app.route("/shiurim/", methods=["GET"])
def shiurim():
    db = firestore.client()
    collection = [
        (shuir.to_dict(), shuir.id) for shuir in db.collection("content").get()
    ]
    return render_template("shiurim.html", data=collection)


@app.route("/shiurim/<ID>", methods=["GET", "POST"])
def shiurimDetail(ID):
    if request.method == "GET":
        db = firestore.client()
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
        db = firestore.client()
        collection = db.collection("content").document(ID)
        collection.delete()
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
        file.save(file.filename)

        attributionID = rabbi[0]
        author = rabbi[1]
        description = request.form.get("description", "")

        # load FileStorage video in cv2
        cap = cv2.VideoCapture(file.filename)
        # Get video length
        length = cap.get(cv2.CAP_PROP_POS_MSEC)

        # Title:
        title = request.form.get("title", "")

        # Content Type:
        content_type = request.form.get("type", "")

        # Source Path:
        #   Based on the file type, decide on the source path.
        #   Part of this process will be to give the file a
        #   unique name based on the rabbi's name and the date.
        source_path = f"HLSStreams/{content_type}/{file.filename}/{file.filename}.m3u8"

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
            # "duration": 0,
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
        # blob.content_type = file.content_type
        # blob.upload_from_file(file)
        return "Done"
        # Make a success page with a link to upload another file
    # except Exception:
    #     return (
    #         "Sorry, it seems like an error occurred. "
    #         + "If this is the first time you are seeing this error, "
    #         + "please try again. If this error persists, please "
    #         + "contact the site administrator.",
    #         500,
    #     )


if __name__ == "__main__":
    app.run(debug=True)
