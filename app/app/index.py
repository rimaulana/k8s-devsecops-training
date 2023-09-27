from flask import Flask
from flask_cors import CORS
from flask_wtf import CSRFProtect

app = Flask(__name__)
csrf = CSRFProtect()
csrf.init_app(app)
CORS(app, origins=["http://localhost:5000","*.devsecops-training.com"])


@app.route("/")
def hello():
    return "Hello World!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int("5000"), debug=True)