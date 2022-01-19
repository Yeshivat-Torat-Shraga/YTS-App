from flask import Flask
from flask_basicauth import BasicAuth
import settings
app = Flask(__name__)
basic_auth = BasicAuth(app)

app.config['BASIC_AUTH_USERNAME'] = settings.username
app.config['BASIC_AUTH_PASSWORD'] = settings.password
app.config['BASIC_AUTH_FORCE'] = True

@app.route("/")
def home():
    return "Home Page"
    
if __name__ == "__main__":
    app.run(debug=True)
    
