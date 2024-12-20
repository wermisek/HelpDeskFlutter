const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const Database = require('better-sqlite3');
const bcrypt = require('bcrypt');
const app = express();
const port = 8080;

// Initialize SQLite database
const db = new Database('./users.db', { verbose: console.log });

// Middleware to parse JSON bodies
app.use(bodyParser.json());

// Serve index.html on the root URL
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Serve static files from the "public" directory
app.use(express.static(path.join(__dirname, 'public')));

try {
    // Add 'comment' column to problems table if it doesn't exist
    db.pragma('foreign_keys = OFF');
    
    try {
        db.prepare('ALTER TABLE problems ADD COLUMN comment TEXT DEFAULT NULL').run();
        console.log('Column "comment" added to "problems" table.');
    } catch (err) {
        if (err.message.includes("duplicate column name: comment")) {
            console.log('Column "comment" already exists in "problems" table.');
        } else {
            console.error('Error adding comment column:', err.message);
        }
    }

    try {
        db.prepare('ALTER TABLE problems ADD COLUMN category TEXT DEFAULT NULL').run();
        console.log('Column "category" added to "problems" table.');
    } catch (err) {
        if (err.message.includes("duplicate column name: category")) {
            console.log('Column "category" already exists in "problems" table.');
        } else {
            console.error('Error adding category column:', err.message);
        }
    }

    try {
        db.prepare('ALTER TABLE problems ADD COLUMN priority TEXT DEFAULT "low"').run();
        console.log('Column "priority" added to "problems" table.');
    } catch (err) {
        if (err.message.includes("duplicate column name: priority")) {
            console.log('Column "priority" already exists in "problems" table.');
        } else {
            console.error('Error adding priority column:', err.message);
        }
    }

    db.pragma('foreign_keys = ON');

    // Create users table if it doesn't exist
    db.prepare(`
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            role TEXT CHECK(role IN ('user', 'admin')) NOT NULL
        )
    `).run();
    console.log('Users table initialized');

    // Create problems table if it doesn't exist
    db.prepare(`
        CREATE TABLE IF NOT EXISTS problems (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            room TEXT NOT NULL,
            problem TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            read INTEGER DEFAULT 0,
            category TEXT CHECK(category IN ('hardware', 'software', 'network', 'printer', 'other')) DEFAULT NULL,
            priority TEXT CHECK(priority IN ('low', 'medium', 'high')) DEFAULT 'low'
        )
    `).run();
    console.log('Problems table initialized');
} catch (err) {
    console.error('Database initialization error:', err.message);
    process.exit(1);
}

// Endpoint to register a new user
app.post('/register', (req, res) => {
    const { username, password, role } = req.body;

    if (!username || !password || !role) {
        return res.status(400).send({ message: 'Username, password, and role are required' });
    }

    if (!['user', 'admin'].includes(role)) {
        return res.status(400).send({ message: 'Role must be either "user" or "admin"' });
    }

    try {
        const hashedPassword = bcrypt.hashSync(password, 10);
        const stmt = db.prepare('INSERT INTO users (username, password, role) VALUES (?, ?, ?)');
        stmt.run(username, hashedPassword, role);
        res.status(201).send({ message: 'User registered successfully' });
    } catch (err) {
        console.error('Error inserting user:', err.message);
        if (err.message.includes('UNIQUE')) {
            return res.status(400).send({ message: 'Username already exists' });
        }
        return res.status(500).send({ message: 'Error registering user' });
    }
});

// Endpoint to login a user
app.post('/login', (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).send({ message: 'Username and password are required' });
    }

    try {
        const stmt = db.prepare('SELECT * FROM users WHERE username = ?');
        const user = stmt.get(username);

        if (!user) {
            return res.status(401).send({ message: 'User not found' });
        }

        const isMatch = bcrypt.compareSync(password, user.password);
        if (!isMatch) {
            return res.status(401).send({ message: 'Invalid password' });
        }

        res.status(200).send({ message: 'Login successful', role: user.role });
    } catch (err) {
        console.error('Error logging in:', err.message);
        res.status(500).send({ message: 'Internal server error' });
    }
});

// Endpoint to add a new problem
app.post('/add_problem', (req, res) => {
    const { username, room, problem, category, priority } = req.body;

    if (!username || !room || !problem) {
        return res.status(400).send({ message: 'Username, room, and problem are required' });
    }

    try {
        const stmt = db.prepare('INSERT INTO problems (username, room, problem, category, priority) VALUES (?, ?, ?, ?, ?)');
        stmt.run(username, room, problem, category || 'other', priority || 'low');
        res.status(201).send({ message: 'Problem added successfully' });
    } catch (err) {
        console.error('Error inserting problem:', err.message);
        return res.status(500).send({ message: 'Error adding problem' });
    }
});

// Endpoint to get all problems
app.get('/get_problems', (req, res) => {
    try {
        const stmt = db.prepare('SELECT * FROM problems');
        const problems = stmt.all();
        res.status(200).json(problems);
    } catch (err) {
        console.error('Error fetching problems:', err.message);
        return res.status(500).send({ message: 'Error fetching problems' });
    }
});

// Endpoint to get unread problems
app.get('/get_unread_problems', (req, res) => {
    try {
        const stmt = db.prepare('SELECT * FROM problems WHERE read = 0');
        const problems = stmt.all();
        res.status(200).json(problems);
    } catch (err) {
        console.error('Error fetching unread problems:', err.message);
        return res.status(500).send({ message: 'Error fetching unread problems' });
    }
});

// Endpoint to mark a problem as read
app.put('/mark_as_read/:id', (req, res) => {
    const problemId = req.params.id;

    if (!problemId) {
        return res.status(400).send({ message: 'Invalid problem ID' });
    }

    try {
        const stmt = db.prepare('UPDATE problems SET read = 1 WHERE id = ?');
        const result = stmt.run(problemId);

        if (result.changes === 0) {
            return res.status(404).send({ message: 'Problem not found' });
        }

        res.status(200).send({ message: 'Problem marked as read' });
    } catch (err) {
        console.error('Error updating problem:', err.message);
        return res.status(500).send({ message: 'Error marking problem as read' });
    }
});

// Endpoint to delete a problem by ID
app.delete('/delete_problem/:id', (req, res) => {
    const problemId = parseInt(req.params.id);

    if (!problemId) {
        return res.status(400).send({ message: 'Invalid problem ID' });
    }

    try {
        const stmt = db.prepare('DELETE FROM problems WHERE id = ?');
        const result = stmt.run(problemId);

        if (result.changes === 0) {
            return res.status(404).send({ message: 'Problem not found' });
        }

        res.status(200).send({ message: 'Problem deleted successfully' });
    } catch (err) {
        console.error('Error deleting problem:', err.message);
        return res.status(500).send({ message: 'Error deleting problem' });
    }
});

// Endpoint to get all users
app.get('/get_users', (req, res) => {
    try {
        const stmt = db.prepare('SELECT id, username, role FROM users');
        const users = stmt.all();
        res.status(200).json(users);
    } catch (err) {
        console.error('Error fetching users:', err.message);
        return res.status(500).send({ message: 'Error fetching users' });
    }
});

// Endpoint to update problem priority
app.put('/update_priority/:id', (req, res) => {
    const problemId = req.params.id;
    const { priority } = req.body;

    if (!problemId || !priority) {
        return res.status(400).send({ message: 'Problem ID and priority are required' });
    }

    if (!['low', 'medium', 'high'].includes(priority)) {
        return res.status(400).send({ message: 'Priority must be low, medium, or high' });
    }

    try {
        const stmt = db.prepare('UPDATE problems SET priority = ? WHERE id = ?');
        const result = stmt.run(priority, problemId);

        if (result.changes === 0) {
            return res.status(404).send({ message: 'Problem not found' });
        }

        res.status(200).send({ message: 'Priority updated successfully' });
    } catch (err) {
        console.error('Error updating priority:', err.message);
        return res.status(500).send({ message: 'Error updating priority' });
    }
});

// Start the server
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});