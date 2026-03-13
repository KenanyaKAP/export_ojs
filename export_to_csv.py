import csv
import os
import mysql.connector
from mysql.connector import Error

# ============================================================
# CONFIGURATION CONSTANTS
# ============================================================
# DB_HOST     = "127.0.0.1"
# DB_PORT     = 3386
# DB_USER     = "root"
# DB_PASSWORD = "ITSjournals123!#"
# DB_NAME     = "journals"

DB_HOST     = "127.0.0.1"
DB_PORT     = 3376
DB_USER     = "root"
DB_PASSWORD = "rootpassword"
DB_NAME     = "ojs"

# DB_HOST     = "127.0.0.1"
# DB_PORT     = 33063
# DB_USER     = "ojs_3213_v2"
# DB_PASSWORD = "0j5_3lektr0_*1=^@~2025"
# DB_NAME     = "ojs_3213_v2"

# DB_HOST     = "127.0.0.1"
# DB_PORT     = 3406
# DB_USER     = "jaree"
# DB_PASSWORD = ".jaree123.JAREE-"
# DB_NAME     = "jaree"

EXPORT_FOLDER = "./ojsnew"
# ============================================================


def get_connection():
    """Create and return a MySQL database connection."""
    connection = mysql.connector.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
    )
    return connection


def get_all_tables(cursor):
    """Retrieve all table names from the database."""
    cursor.execute("SHOW TABLES;")
    tables = [row[0] for row in cursor.fetchall()]
    return tables


def export_table_to_csv(cursor, table_name, export_folder):
    """Export a single table to a CSV file."""
    file_path = os.path.join(export_folder, f"{table_name}.csv")

    cursor.execute(f"SELECT * FROM `{table_name}`;")
    rows = cursor.fetchall()
    column_names = [desc[0] for desc in cursor.description]

    with open(file_path, mode="w", newline="", encoding="utf-8") as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(column_names)
        writer.writerows(rows)

    print(f"  [OK] {table_name} -> {file_path}  ({len(rows)} rows)")


def main():
    # Ensure the export folder exists
    os.makedirs(EXPORT_FOLDER, exist_ok=True)

    try:
        print(f"Connecting to database '{DB_NAME}' at {DB_HOST}:{DB_PORT} ...")
        connection = get_connection()
        cursor = connection.cursor()

        tables = get_all_tables(cursor)
        print(f"Found {len(tables)} table(s). Starting export...\n")

        for table in tables:
            export_table_to_csv(cursor, table, EXPORT_FOLDER)

        print(f"\nExport complete. All CSV files saved to: {os.path.abspath(EXPORT_FOLDER)}")

    except Error as e:
        print(f"[ERROR] MySQL error: {e}")

    finally:
        if "cursor" in locals() and cursor:
            cursor.close()
        if "connection" in locals() and connection.is_connected():
            connection.close()
            print("Database connection closed.")


if __name__ == "__main__":
    main()
