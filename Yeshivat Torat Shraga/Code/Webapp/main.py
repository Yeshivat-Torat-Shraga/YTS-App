from datetime import datetime
from flask import Flask, render_template, request, url_for
from flask_basicauth import BasicAuth
import cv2

# import settings
from firebase_admin import credentials, initialize_app, storage, firestore

cred = credentials.Certificate("cred.json")
initialize_app(cred, {"storageBucket": "yeshivat-torat-shraga.appspot.com"})

app = Flask(__name__)
basic_auth = BasicAuth(app)

app.config["BASIC_AUTH_USERNAME"] = "username"  # settings.username
app.config["BASIC_AUTH_PASSWORD"] = ""  # settings.password
app.config["BASIC_AUTH_FORCE"] = True


@app.route("/shiurim/upload/", methods=["GET", "POST"])
def shiurim_upload():
    rabbis = []
    db = firestore.client()
    collection = db.collection("rebbeim")
    if request.method == "GET":
        # documents = collection.list_documents()
        rabbis = [
            {
                "name": "Rabbi Shlomo",
                "id": "shlomo",
            }
        ]
        # for doc in documents:
        #     doc = doc.get()
        #     doc_dict = doc.to_dict()
        #     doc_dict["id"] = doc.id
        #     rabbis.append(doc_dict)
        # rabbis = [rabbi.get().to_dict().get("name") for rabbi in documents]
        return render_template("shiur_upload.html", rabbis=rabbis, type="Shiurim")
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
        collection.add(
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
