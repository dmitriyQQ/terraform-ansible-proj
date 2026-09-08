from flask import Flask, render_template, request, redirect
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

def get_db_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        database=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )

@app.route("/", methods=["GET", "POST"])
def index():
    connection = get_db_connection()
    cursor = connection.cursor()

    if request.method == "POST":
        title = request.form["title"]
        content = request.form["content"]

        cursor.execute(
            "INSERT INTO notes (title, content) VALUES (%s, %s);",
            (title, content)
        )

        connection.commit()

        cursor.close()
        connection.close()

        return redirect("/")

    cursor.execute(
        "SELECT id, title, content, created_at FROM notes ORDER BY id DESC;"
    )

    notes = cursor.fetchall()

    cursor.close()
    connection.close()

    return render_template("index.html", notes=notes)


@app.route("/edit/<int:note_id>", methods=["GET", "POST"])
def edit_note(note_id):
    connection = get_db_connection()
    cursor = connection.cursor()

    if request.method == "POST":
        title = request.form["title"]
        content = request.form["content"]

        cursor.execute(
            """
            UPDATE notes
            SET title = %s,
                content = %s
            WHERE id = %s;
            """,
            (title, content, note_id)
        )

        connection.commit()

        cursor.close()
        connection.close()

        return redirect("/")

    cursor.execute(
        "SELECT id, title, content, created_at FROM notes WHERE id = %s;",
        (note_id,)
    )

    note = cursor.fetchone()

    cursor.close()
    connection.close()

    return render_template("edit.html", note=note)


@app.route("/delete/<int:note_id>", methods=["POST"])
def delete_note(note_id):
    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute(
        "DELETE FROM notes WHERE id = %s;",
        (note_id,)
    )

    connection.commit()

    cursor.close()
    connection.close()

    return redirect("/")


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000)
