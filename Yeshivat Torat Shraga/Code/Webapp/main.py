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
    if request.method == "GET":
        rebbeim_docs = rebbeim_collection.list_documents()
        tag_docs = tags_collection.list_documents()
        rabbis = []
        tags = []
        for doc in rebbeim_docs:
            doc = doc.get()
            doc_dict = doc.to_dict()
            doc_dict["id"] = doc.id
            rabbis.append(doc_dict)
        for tag in tag_docs:
            tag = tag.get()
            tag_dict = tag.to_dict()
            tag_dict["id"] = tag.id
            tags.append(tag_dict)
        return render_template(
            "shiur_upload.html", rabbis=rabbis, type="Shiurim", tags=tags
        )
    else:
        # The firestore document for content has the following structure:
        # {
        #     "attributionID": "",
        #     "author": "",
        #     "date": datetime.now(),
        #     "description": "",
        #     "duration": "",
        #     "search_index": "",
        #     "source_path": "",
        #     "tags": [],
        #     "title": "",
        #     "type": "",
        # }

        title = request.form["title"]
        rabbi = request.form["author"].split("~")
        attributionID = rabbi[0]
        name = rabbi[1]
        file = request.files["file"]
        # get the duration of the video using OpenCV
        cap = cv2.VideoCapture(file)
        duration = cap.get(cv2.CAP_PROP_POS_MSEC) / 1000
        # Rename the file to the document ID of the firestore document we will create
        # In the cloud function, we will use the filename to identify the document
        # and then use the document ID to update the document with the correct source_path
        rebbeim_collection.add(
            {
                "attributionID": attributionID,
                "author": name,
                "date": datetime.now(),
                "description": request.form["description"],
                "duration": duration,
                "search_index": title.split(" "),
                "source_path": "HLSStreams/{}".format(request.form["type"]),
                "tags": [],
                "title": title,
                "type": request.form["type"],
            }
        )
        # bucket = storage.bucket()
        # blob = bucket.blob(f"profile-pictures/{file.filename}")
        # blob.content_type = file.content_type
        # blob.upload_from_file(file)
        return "Done"


if __name__ == "__main__":
    app.run(debug=True)
