# MOTOPP – Flask + MySQL Multi-Container Application with CI/CD Pipeline

## 📘 Overview
**MOTOPP** is a containerized web application built with **Flask** and **MySQL**.  
It demonstrates a **multi-container Docker architecture** with a **continuous integration and deployment (CI/CD)** pipeline using **GitHub Actions**.  
---

## ⚙️ Tech Stack
- **Backend:** Flask (Python 3.9)
- **Database:** MySQL 8
- **Containerization:** Docker & Docker Compose
- **Pipeline:** GitHub Actions
- **Deployment:** Docker Hub (Automated Image Push)

---
## Local Run
To run a local instance of the app, you need to have docker and docker-compose installed.
Then run:
```Bash
git clone
touch .env
```

Add the following configurations to the `.env` file:
```bash
SECRET_KEY=your_secret_key
MYSQL_PASSWORD=your_mysql_password
```
Finally, run:
```Bash
docker-compose up --build 
```

Access the application:
- Open your browser and navigate to `http://localhost:5000`
- Create a new account or log in with existing credentials
