from flask import Flask, render_template, request, url_for
from flask_basicauth import BasicAuth
import settings
from firebase_admin import credentials, initialize_app, storage, firestore

cred = credentials.Certificate("cred.json")
initialize_app(
    cred, {'storageBucket':'yeshivat-torat-shraga.appspot.com'}
)

app = Flask(__name__)
basic_auth = BasicAuth(app)

app.config['BASIC_AUTH_USERNAME'] = settings.username
app.config['BASIC_AUTH_PASSWORD'] = settings.password
app.config['BASIC_AUTH_FORCE'] = True

@app.route("/",  methods=["GET", "POST"])
def home():
    db = firestore.client()
    collection = db.collection("rebbeim")
    if request.method == "GET":
        documents = collection.list_documents(page_size=2)
        rabbis = [rabbi.get().to_dict().get("name") for rabbi in documents ]
        return render_template("home.html", rabbis=rabbis)
    else:
        name = request.form["title"]
        file  = request.files['file']
        collection.add({"name":name, "profile_picture_filename":file.filename, "search_index":name.split(" ") })
        bucket = storage.bucket()
        blob=bucket.blob(f"profile-pictures/{file.filename}")
        blob.content_type = file.content_type
        blob.upload_from_file(file) 
        return "Done"
    
if __name__ == "__main__":
    app.run(debug=True)
    
