import { useState } from "react";

function App() {
  const [doubts, setDoubts] = useState([]);

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");

  const [name, setName] = useState("");
  const [role, setRole] = useState("");

  // ADD DOUBT
  const addDoubt = () => {
    if (!title || !description) {
      alert("Fill all fields");
      return;
    }

    const newDoubt = {
      _id: Date.now().toString(),
      title,
      description,
      status: "OPEN",
      acceptedBy: null
    };

    setDoubts([...doubts, newDoubt]);

    setTitle("");
    setDescription("");
  };

  // ACCEPT DOUBT
  const acceptDoubt = (id) => {
    if (!name || !role) {
      alert("Enter name and role");
      return;
    }

    const userIdentity = `${name} (${role})`;

    setDoubts(doubts.map(d =>
      d._id === id && d.status === "OPEN"
        ? { ...d, status: "MATCHED", acceptedBy: userIdentity }
        : d
    ));
  };

  return (
    <div style={{ padding: 30, maxWidth: 800, margin: "auto" }}>

      <h1 style={{ textAlign: "center" }}>DoubtSphere 🚀</h1>

      {/* USER INFO */}
      <input
        placeholder="Enter your name"
        value={name}
        onChange={(e) => setName(e.target.value)}
        style={{ margin: 5 }}
      />

      <select
        value={role}
        onChange={(e) => setRole(e.target.value)}
        style={{ margin: 5 }}
      >
        <option value="">Select Role</option>
        <option value="Guide">Guide</option>
        <option value="User">User</option>
      </select>

      {/* ADD DOUBT */}
      <div style={{ marginTop: 20 }}>
        <input
          placeholder="Title"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          style={{ margin: 5 }}
        />

        <input
          placeholder="Description"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          style={{ margin: 5 }}
        />

        <button onClick={addDoubt}>
          Add Doubt
        </button>
      </div>

      {/* LIST */}
      <div style={{ marginTop: 30 }}>
        {doubts.length === 0 ? (
          <p>No doubts yet</p>
        ) : (
          doubts.map((d) => (
            <div
              key={d._id}
              style={{
                border: "1px solid gray",
                margin: 10,
                padding: 10
              }}
            >
              <p>👤 {d.acceptedBy || "Not accepted yet"}</p>

              <h3>{d.title}</h3>
              <p>{d.description}</p>

              <p style={{
                color: d.status === "OPEN" ? "green" : "red",
                fontWeight: "bold"
              }}>
                {d.status}
              </p>

              <button
                onClick={() => acceptDoubt(d._id)}
                disabled={d.status !== "OPEN"}
              >
                {d.status === "OPEN"
                  ? "Accept"
                  : "Already Accepted"}
              </button>
            </div>
          ))
        )}
      </div>

    </div>
  );
}

export default App;