import sqlalchemy as sa


# authenticate to postgres using the system_user
engine = sa.create_engine(
    "postgresql://system_user:insecure-pass-for-demo-app@localhost:5432/app"
)

engine_ro = sa.create_engine(
    "postgresql://readonly_user:insecure-pass-for-demo-readonly@localhost:5432/app"
)



sql = "SELECT 1"

with engine.connect() as conn:
    result = conn.execute(sa.text(sql))
    assert result.fetchall() == [(1,)]

# create tables
create_tables_sqls = []

create_tables_sql_users = """
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
"""
create_tables_sqls.append(create_tables_sql_users)

create_tables_sql_categories = """
CREATE TABLE IF NOT EXISTS categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
"""
create_tables_sqls.append(create_tables_sql_categories)

create_tables_sql_todos = """
CREATE TABLE IF NOT EXISTS todos (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  category_id INTEGER REFERENCES categories(id),
  title VARCHAR(100) NOT NULL,
  description TEXT,
  due_date DATE,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"""
create_tables_sqls.append(create_tables_sql_todos)

print("Creating tables")
with engine.connect() as conn:
    for sql in create_tables_sqls:
        conn.execute(sa.text(sql))
        conn.commit()
print("Tables created")


# list all tables in the app database
sql = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"

print("Validating tables")
with engine.connect() as conn:
    result = conn.execute(sa.text(sql))
    tables = result.fetchall()
    print(f"Tables from the database: {tables}")
    assert tables == [('users',), ('categories',), ('todos',)], "Tables are not created"
print("Tables validated")

# Insert test data
insert_users_sqls = [
    """
    INSERT INTO users (id, username, email) VALUES
    (1, 'alice', 'alice@example.com'),
    (2, 'bob', 'bob@example.com'),
    (3, 'charlie', 'charlie@example.com');
    """,

    """
    INSERT INTO categories (id, name) VALUES
    (1, 'Work'),
    (2, 'Personal'),
    (3, 'Errands');
    """, 

    """
    INSERT INTO todos (user_id, category_id, title, description, due_date, completed) VALUES
    (1, 1, 'Finish project', 'Complete the infrastructure project.', '2025-04-30', FALSE),
    (2, 2, 'Buy groceries', 'Milk, Bread, Eggs', '2025-04-23', FALSE),
    (3, 3, 'Doctor appointment', 'Annual check-up at 3 PM.', '2025-04-25', FALSE),
    (1, 2, 'Call mom', 'Check in with family.', '2025-04-24', FALSE),
    (2, 1, 'Write blog post', 'Post about PostgreSQL role management.', '2025-04-27', TRUE);
    """
]

print("Inserting test data")
with engine.connect() as conn:
    # drop existing data
    conn.execute(sa.text("TRUNCATE TABLE todos CASCADE"))
    conn.commit()

    conn.execute(sa.text("TRUNCATE TABLE categories CASCADE"))
    conn.commit()

    conn.execute(sa.text("TRUNCATE TABLE users CASCADE"))
    conn.commit()
    

    for sql in insert_users_sqls:
        conn.execute(sa.text(sql))
        conn.commit()
print("Test data inserted")

# Query Users
sql = "SELECT username, email FROM users"

print("Validating users")
with engine.connect() as conn:
    result = conn.execute(sa.text(sql))
    users = result.fetchall()
    print(f"Users from the database: {users}")
    assert users == [('alice', 'alice@example.com'), ('bob', 'bob@example.com'), ('charlie', 'charlie@example.com')]
print("Users validated")
