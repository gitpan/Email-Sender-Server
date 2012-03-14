
CREATE TABLE "message" (
    "id" INTEGER PRIMARY KEY,
    "worker" INTEGER DEFAULT NULL,
    "attempt" INTEGER DEFAULT 0,
    "status" TEXT DEFAULT "queued",
    "to" TEXT NOT NULL,
    "reply_to" TEXT,
    "from" TEXT NOT NULL,
    "cc" TEXT,
    "bcc" TEXT,
    "subject" TEXT NOT NULL,
    "body_text" TEXT,
    "body_html" TEXT,
    "created" TEXT,
    "updated" TEXT
);

CREATE TABLE "attachment" (
    "id" INTEGER PRIMARY KEY,
    "message" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    FOREIGN KEY("message") REFERENCES "message"("id")
);

CREATE TABLE "header" (
    "id" INTEGER PRIMARY KEY,
    "message" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    FOREIGN KEY("message") REFERENCES "message"("id")
);

CREATE TABLE "log" (
    "id" INTEGER PRIMARY KEY,
    "message" INTEGER NOT NULL,
    "report" TEXT NOT NULL,
    "created" TEXT NOT NULL,
    FOREIGN KEY("message") REFERENCES "message"("id")
);

CREATE TABLE "tag" (
    "id" INTEGER PRIMARY KEY,
    "message" INTEGER NOT NULL,
    "value" TEXT NOT NULL,
    FOREIGN KEY("message") REFERENCES "message"("id")
);
