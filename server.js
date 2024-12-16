const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcrypt');
const app = express();
const port = 8080;

// Initialize SQLite database
const db = new sqlite3.Database('./users.db', (err) => {
  if (err) {
    console.error('Error opening database:', err.message);
    process.exit(1);
  }
});

// Middleware to parse JSON bodies
app.use(bodyParser.json());

// Serve index.html on the root URL
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Serve static files from the "public" directory
app.use(express.static(path.join(__dirname, 'public')));

    // Add 'read' column to problems table if it doesn't exist
    db.run(`PRAGMA foreign_keys=off;`, (err) => {
      if (err) {
        console.error('Error disabling foreign keys:', err.message);
      } else {
        db.run(
          `ALTER TABLE problems ADD COLUMN comment TEXT DEFAULT NULL`,
          (err) => {
            if (err && err.message.includes("duplicate column name: comment")) {
              console.log('Column "comment" already exists in "problems" table.');
            } else if (err) {
              console.error('Error adding comment column:', err.message);
            } else {
              console.log('Column "comment" added to "problems" table.');
            }
          }
        );
    db.run(`PRAGMA foreign_keys=on;`);

    // Create users table if it doesn't exist
    db.run(
      `CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT CHECK(role IN ('user', 'admin')) NOT NULL
      )`,
      (err) => {
        if (err) {
          console.error('Error creating users table:', err.message);
        } else {
          console.log('Users table initialized');
        }
      }
    );

    // Create problems table if it doesn't exist
    db.run(
      `CREATE TABLE IF NOT EXISTS problems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        room TEXT NOT NULL,
        problem TEXT NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        read INTEGER DEFAULT 0
      )`,
      (err) => {
        if (err) {
          console.error('Error creating problems table:', err.message);
        } else {
          console.log('Problems table initialized');
        }
      }
    );
  }
});

// Endpoint to register a new user
app.post('/register', (req, res) => {
  const { username, password, role } = req.body;

  if (!username || !password || !role) {
    return res.status(400).send({ message: 'Username, password, and role are required' });
  }

  if (!['user', 'admin'].includes(role)) {
    return res.status(400).send({ message: 'Role must be either "user" or "admin"' });
  }

  bcrypt.hash(password, 10, (err, hashedPassword) => {
    if (err) {
      console.error('Error hashing password:', err.message);
      return res.status(500).send({ message: 'Error hashing password' });
    }

    db.run(
      `INSERT INTO users (username, password, role) VALUES (?, ?, ?)`,
      [username, hashedPassword, role],
      function (err) {
        if (err) {
          console.error('Error inserting user:', err.message);
          if (err.message.includes('UNIQUE')) {
            return res.status(400).send({ message: 'Username already exists' });
          }
          return res.status(500).send({ message: 'Error registering user' });
        }
        res.status(201).send({ message: 'User registered successfully' });
      }
    );
  });
});

// Endpoint to login a user
app.post('/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).send({ message: 'Username and password are required' });
  }

  try {
    db.get(
      `SELECT * FROM users WHERE username = ?`,
      [username],
      async (err, row) => {
        if (err) {
          console.error('Error fetching user:', err.message);
          return res.status(500).send({ message: 'Internal server error' });
        }
        if (!row) {
          return res.status(401).send({ message: 'User not found' });
        }

        const isMatch = await bcrypt.compare(password, row.password);
        if (!isMatch) {
          return res.status(401).send({ message: 'Invalid password' });
        }

        res.status(200).send({ message: 'Login successful', role: row.role });
      }
    );
  } catch (err) {
    console.error('Error logging in:', err.message);
    res.status(500).send({ message: 'Internal server error' });
  }
});

// Endpoint to add a new problem
app.post('/add_problem', (req, res) => {
  const { username, room, problem } = req.body;

  if (!username || !room || !problem) {
    return res.status(400).send({ message: 'Username, room, and problem are required' });
  }

  db.run(
    `INSERT INTO problems (username, room, problem) VALUES (?, ?, ?)`,
    [username, room, problem],
    function (err) {
      if (err) {
        console.error('Error inserting problem:', err.message);
        return res.status(500).send({ message: 'Error adding problem' });
      }
      res.status(201).send({ message: 'Problem added successfully' });
    }
  );
});

// Endpoint to get all problems
app.get('/get_problems', (req, res) => {
  db.all(`SELECT * FROM problems`, [], (err, rows) => {
    if (err) {
      console.error('Error fetching problems:', err.message);
      return res.status(500).send({ message: 'Error fetching problems' });
    }
    res.status(200).json(rows);
  });
});

// Endpoint to get unread problems
app.get('/get_unread_problems', (req, res) => {
  db.all(`SELECT * FROM problems WHERE read = 0`, [], (err, rows) => {
    if (err) {
      console.error('Error fetching unread problems:', err.message);
      return res.status(500).send({ message: 'Error fetching unread problems' });
    }
    res.status(200).json(rows);
  });
});

// Endpoint to mark a problem as read
app.put('/mark_as_read/:id', (req, res) => {
  const problemId = req.params.id;

  if (!problemId) {
    return res.status(400).send({ message: 'Invalid problem ID' });
  }

  db.run(`UPDATE problems SET read = 1 WHERE id = ?`, [problemId], function (err) {
    if (err) {
      console.error('Error updating problem:', err.message);
      return res.status(500).send({ message: 'Error marking problem as read' });
    }

    if (this.changes === 0) {
      return res.status(404).send({ message: 'Problem not found' });
    }

    res.status(200).send({ message: 'Problem marked as read' });
  });
});

// Endpoint to delete a problem by ID
app.delete('/delete_problem/:id', (req, res) => {
  const problemId = parseInt(req.params.id);

  if (!problemId) {
    return res.status(400).send({ message: 'Invalid problem ID' });
  }

  db.run(`DELETE FROM problems WHERE id = ?`, [problemId], function (err) {
    if (err) {
      console.error('Error deleting problem:', err.message);
      return res.status(500).send({ message: 'Error deleting problem' });
    }

    if (this.changes === 0) {
      return res.status(404).send({ message: 'Problem not found' });
    }

    res.status(200).send({ message: 'Problem deleted successfully' });
  });
});

// Endpoint to get all users
app.get('/get_users', (req, res) => {
  db.all(`SELECT id, username, role FROM users`, [], (err, rows) => {
    if (err) {
      console.error('Error fetching users:', err.message);
      return res.status(500).send({ message: 'Error fetching users' });
    }
    res.status(200).json(rows);
  });
});

// Endpoint to update comment
app.put('/update_comment/:id', (req, res) => {
  const problemId = parseInt(req.params.id);
  const { comment } = req.body;

  if (!problemId) {
    return res.status(400).send({ message: 'Invalid problem ID' });
  }

  if (!comment) {
    return res.status(400).send({ message: 'Comment is required' });
  }

  db.run(`UPDATE problems SET comment = ? WHERE id = ?`, [comment, problemId], function (err) {
    if (err) {
      console.error('Error updating comment:', err.message);
      return res.status(500).send({ message: 'Error updating comment' });
    }

    if (this.changes === 0) {
      return res.status(404).send({ message: 'Problem not found' });
    }

    res.status(200).send({ message: 'Comment updated successfully' });
  });
});

// Endpoint to change username
app.put('/change_username', (req, res) => {
  const { oldUsername, newUsername } = req.body;

  if (!oldUsername || !newUsername) {
    return res.status(400).send({ message: 'Old username and new username are required' });
  }

  db.get(`SELECT * FROM users WHERE username = ?`, [oldUsername], (err, row) => {
    if (err) {
      console.error('Error fetching user:', err.message);
      return res.status(500).send({ message: 'Internal server error' });
    }
    if (!row) {
      return res.status(404).send({ message: 'User not found' });
    }

    db.run(`UPDATE users SET username = ? WHERE username = ?`, [newUsername, oldUsername], function (err) {
      if (err) {
        console.error('Error updating username:', err.message);
        return res.status(500).send({ message: 'Error updating username' });
      }
      res.status(200).send({ message: 'Username updated successfully' });
    });
  });
});
// Endpoint to change password (admin only)
app.put('/change_password', (req, res) => {
  const { username, newPassword } = req.body;

  if (!username || !newPassword) {
    return res.status(400).send({ message: 'Username and new password are required' });
  }

  const currentUserRole = req.headers['role']; // Pobierz rolę użytkownika z nagłówka

  if (currentUserRole !== 'admin') {
    return res.status(403).send({ message: 'You do not have permission to change passwords' });
  }

  bcrypt.hash(newPassword, 10, (err, hashedPassword) => {
    if (err) {
      console.error('Error hashing password:', err.message);
      return res.status(500).send({ message: 'Error hashing password' });
    }

    db.run(`UPDATE users SET password = ? WHERE username = ?`, [hashedPassword, username], function (err) {
      if (err) {
        console.error('Error updating password:', err.message);
        return res.status(500).send({ message: 'Error updating password' });
      }

      if (this.changes === 0) {
        return res.status(404).send({ message: 'User not found' });
      }

      res.status(200).send({ message: 'Password updated successfully' });
    });
  });
});

// Endpoint to delete user (only for admin)
app.delete('/delete_user', (req, res) => {
  const { username } = req.body;

  if (!username) {
    return res.status(400).send({ message: 'Username is required' });
  }

  const currentUserRole = req.headers['role']; 

  if (currentUserRole !== 'admin') {
    return res.status(403).send({ message: 'You do not have permission to delete users' });
  }

  db.run(`DELETE FROM users WHERE username = ?`, [username], function (err) {
    if (err) {
      console.error('Error deleting user:', err.message);
      return res.status(500).send({ message: 'Error deleting user' });
    }

    if (this.changes === 0) {
      return res.status(404).send({ message: 'User not found' });
    }

    res.status(200).send({ message: 'User deleted successfully' });
  });
});
// Endpoint do zmiany hasła przez użytkownika (po podaniu starego hasła)
app.put('/change_password_for_user', (req, res) => {
  const { username, oldPassword, newPassword } = req.body;

  if (!username || !oldPassword || !newPassword) {
    return res.status(400).send({ message: 'Username, old password, and new password are required' });
  }

  // Pobierz użytkownika z bazy danych
  db.get(`SELECT * FROM users WHERE username = ?`, [username], async (err, row) => {
    if (err) {
      console.error('Error fetching user:', err.message);
      return res.status(500).send({ message: 'Internal server error' });
    }
    if (!row) {
      return res.status(404).send({ message: 'User not found' });
    }

    // Porównaj stare hasło
    const isMatch = await bcrypt.compare(oldPassword, row.password);
    if (!isMatch) {
      return res.status(401).send({ message: 'Old password is incorrect' });
    }

    // Hashuj nowe hasło
    bcrypt.hash(newPassword, 10, (err, hashedPassword) => {
      if (err) {
        console.error('Error hashing new password:', err.message);
        return res.status(500).send({ message: 'Error hashing new password' });
      }

      // Zaktualizuj hasło w bazie danych
      db.run(`UPDATE users SET password = ? WHERE username = ?`, [hashedPassword, username], function (err) {
        if (err) {
          console.error('Error updating password:', err.message);
          return res.status(500).send({ message: 'Error updating password' });
        }

        res.status(200).send({ message: 'Password updated successfully' });
      });
    });
  });
});
// Start the server
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
