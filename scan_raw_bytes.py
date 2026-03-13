"""Quick scan: find all rows with raw 0x80-0x9F bytes using MySQL REGEXP at the binary level."""
import mysql.connector

# Use latin1 to read raw bytes - no UTF-8 conversion
conn = mysql.connector.connect(
    host='127.0.0.1', port=3376, user='root', password='rootpassword',
    database='ojs', charset='latin1', use_unicode=False
)
cur = conn.cursor()

# Use a separate connection for INFORMATION_SCHEMA queries
conn2 = mysql.connector.connect(
    host='127.0.0.1', port=3376, user='root', password='rootpassword',
    database='ojs'
)
cur2 = conn2.cursor()

cur2.execute("""
    SELECT TABLE_NAME, COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'ojs'
      AND DATA_TYPE IN ('text', 'mediumtext', 'longtext', 'varchar')
      AND CHARACTER_MAXIMUM_LENGTH > 50
    ORDER BY TABLE_NAME, COLUMN_NAME
""")
columns = cur2.fetchall()
cur2.close()
conn2.close()

print("Scanning for raw 0x80-0x9F bytes in all text columns...")
total_bad = 0
for table_name, col_name in columns:
    try:
        # Use UNHEX to match specific byte ranges
        query = f"""
            SELECT COUNT(*) FROM `{table_name}` 
            WHERE CAST(`{col_name}` AS BINARY) REGEXP CONCAT('[', UNHEX('80'), '-', UNHEX('9F'), ']')
        """
        cur.execute(query)
        result = cur.fetchone()[0]
        count = int(result) if isinstance(result, bytes) else result
        if count > 0:
            print(f"  {table_name}.{col_name}: {count} rows")
            total_bad += count
    except Exception as e:
        pass  # Skip views, etc.

print(f"\nTotal rows with bad raw bytes: {total_bad}")
cur.close()
conn.close()
