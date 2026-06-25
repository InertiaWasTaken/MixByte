from flask import Flask, request, jsonify, render_template
import json
import os

app = Flask(__name__)

SETTINGS_PATH = "/home/inertia/mixbyte/system.json"


# --------------------------
# DEFAULT STATE
# --------------------------
def default_settings():
    return {
        "ssh_enabled": False
    }


# --------------------------
# LOAD SETTINGS (SAFE)
# --------------------------
def load_settings():
    if not os.path.exists(SETTINGS_PATH):
        data = default_settings()
        save_settings(data)
        return data

    try:
        with open(SETTINGS_PATH, "r") as f:
            return json.load(f)
    except Exception:
        data = default_settings()
        save_settings(data)
        return data


# --------------------------
# SAVE SETTINGS
# --------------------------
def save_settings(data):
    os.makedirs(os.path.dirname(SETTINGS_PATH), exist_ok=True)

    with open(SETTINGS_PATH, "w") as f:
        json.dump(data, f, indent=2)


# --------------------------
# UI
# --------------------------
@app.route("/")
def index():
    return render_template("index.html")


# --------------------------
# SETTINGS API
# --------------------------
@app.route("/api/settings", methods=["GET"])
def get_settings():
    return jsonify(load_settings())


@app.route("/api/settings/ssh", methods=["POST"])
def set_ssh():
    data = load_settings()
    req = request.get_json()

    data["ssh_enabled"] = bool(req.get("ssh_enabled", False))
    save_settings(data)

    return "SSH setting updated"


# --------------------------
# POWER CONTROL
# --------------------------
@app.route("/api/reboot", methods=["POST"])
def reboot():
    os.system("sudo reboot")
    return "Rebooting"


@app.route("/api/shutdown", methods=["POST"])
def shutdown():
    os.system("sudo shutdown now")
    return "Shutting down"


# --------------------------
# RUN
# --------------------------
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
