#!/bin/bash
set -e

apt update -y
apt install docker.io -y
systemctl enable docker
systemctl start docker

curl -SL https://github.com/docker/compose/releases/download/v2.39.1/docker-compose-linux-x86_64 \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

mkdir -p /home/ubuntu/app/database /home/ubuntu/app/data

cat > /home/ubuntu/app/docker-compose.yml << 'DOCKERCOMPOSE'
services:
  database:
    image: postgres:15-alpine
    container_name: 3tiers-database
    restart: unless-stopped
    environment:
      POSTGRES_DB: productdb
      POSTGRES_USER: productdb_user
      POSTGRES_PASSWORD: p&Ho8t9p@Cz5CazG
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - 3tiers-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U productdb_user -d productdb"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    image: bbabadara/3tiers-app-backend:latest
    container_name: 3tiers-backend
    restart: unless-stopped
    environment:
      PORT: 5000
      DB_HOST: database
      DB_PORT: 5432
      DB_NAME: productdb
      DB_USER: productdb_user
      DB_PASSWORD: p&Ho8t9p@Cz5CazG
    ports:
      - "5000:5000"
    depends_on:
      database:
        condition: service_healthy
    networks:
      - 3tiers-network

  frontend:
    image: bbabadara/3tiers-app-frontend:latest
    container_name: 3tiers-frontend
    restart: unless-stopped
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - 3tiers-network

volumes:
  postgres_data:
    name: 3tiers-postgres-data

networks:
  3tiers-network:
    name: 3tiers-network
    driver: bridge
DOCKERCOMPOSE

cat > /home/ubuntu/app/database/init.sql << 'INITSQL'
CREATE TABLE IF NOT EXISTS categories (
  id SERIAL PRIMARY KEY,
  nom VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  nom VARCHAR(255) NOT NULL,
  description TEXT,
  prix DECIMAL(10, 2) NOT NULL,
  stock INTEGER NOT NULL DEFAULT 0,
  "categorieId" INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

INSERT INTO categories (nom, description)
SELECT 'Informatique', 'Ordinateurs, composants et périphériques'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE nom = 'Informatique');

INSERT INTO categories (nom, description)
SELECT 'Audio', 'Casques, écouteurs et enceintes'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE nom = 'Audio');

INSERT INTO categories (nom, description)
SELECT 'Accessoires', 'Accessoires et gadgets divers'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE nom = 'Accessoires');

INSERT INTO categories (nom, description)
SELECT 'Mobiles', 'Smartphones, tablettes et accessoires mobiles'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE nom = 'Mobiles');

INSERT INTO categories (nom, description)
SELECT 'Gaming', 'Consoles, jeux et équipement gaming'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE nom = 'Gaming');

INSERT INTO categories (nom, description)
SELECT 'Maison Connectée', 'Objets connectés et domotique'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE nom = 'Maison Connectée');

INSERT INTO products (nom, description, prix, stock, "categorieId")
SELECT 'Ordinateur Portable', 'Ordinateur portable haute performance 16Go RAM', 899.99, 10, (SELECT id FROM categories WHERE nom = 'Informatique')
WHERE NOT EXISTS (SELECT 1 FROM products WHERE nom = 'Ordinateur Portable');

INSERT INTO products (nom, description, prix, stock, "categorieId")
SELECT 'Souris Sans Fil', 'Souris ergonomique sans fil', 29.99, 50, (SELECT id FROM categories WHERE nom = 'Informatique')
WHERE NOT EXISTS (SELECT 1 FROM products WHERE nom = 'Souris Sans Fil');

INSERT INTO products (nom, description, prix, stock, "categorieId")
SELECT 'Clavier Mécanique', 'Clavier mécanique RGB rétroéclairé', 79.99, 30, (SELECT id FROM categories WHERE nom = 'Gaming')
WHERE NOT EXISTS (SELECT 1 FROM products WHERE nom = 'Clavier Mécanique');
INITSQL

chown -R ubuntu:ubuntu /home/ubuntu/app

docker-compose -f /home/ubuntu/app/docker-compose.yml pull
docker-compose -f /home/ubuntu/app/docker-compose.yml up -d
