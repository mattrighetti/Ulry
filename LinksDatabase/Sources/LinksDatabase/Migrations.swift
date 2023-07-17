//
//  File.swift
//  
//
//  Created by Matt on 25/01/2023.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import Foundation

/**
 Restructure of database tables, introduced primary keys instead of unique
 and removed use of foreign keys in favor of triggers

 This update will also load current links in the search virtual table
 */
let migration_1674682062 = """
CREATE TABLE IF NOT EXISTS category_copy (id text not null primary key, name varchar(50) not null, icon varchar(50) not null, color char(7) not null);
INSERT INTO category_copy SELECT * FROM category;

CREATE TABLE IF NOT EXISTS tag_copy (id text not null primary key, name varchar(50) not null, color char(7) not null);
INSERT INTO tag_copy SELECT * FROM tag;

CREATE TABLE IF NOT EXISTS link_copy (id text not null primary key, url text not null, starred bool not null default false, unread bool not null default true, note text, color char(7) not null, ogTitle text, ogDescription text, ogImageUrl text, created_at integer not null, updated_at integer not null);
INSERT INTO link_copy SELECT * FROM link;

CREATE TABLE IF NOT EXISTS category_link_copy (link_id text not null, category_id text not null, primary key (link_id, category_id));
INSERT INTO category_link_copy SELECT * FROM category_link;

CREATE TABLE IF NOT EXISTS tag_link_copy (link_id text not null, tag_id text not null, primary key (link_id, tag_id));
INSERT INTO tag_link_copy SELECT * FROM tag_link;

DROP TABLE if EXISTS category_link;DROP TABLE if EXISTS category;DROP TABLE if EXISTS tag;DROP TABLE if EXISTS link;DROP TABLE if EXISTS tag_link;
ALTER TABLE category_link_copy RENAME TO category_link;ALTER TABLE category_copy RENAME TO category;ALTER TABLE tag_copy RENAME TO tag;ALTER TABLE link_copy RENAME TO link;ALTER TABLE tag_link_copy RENAME TO tag_link;

INSERT INTO search SELECT id, url, ogTitle, ogDescription FROM link;
INSERT INTO migrations (version) values (1674682062);

ALTER TABLE link ADD COLUMN archived bool not null default false;

CREATE TRIGGER if not EXISTS on_link_update_update_lookup AFTER UPDATE ON link BEGIN update search set title = NEW.ogTitle, url = NEW.url, description = NEW.ogDescription where id = NEW.id; END;
CREATE TRIGGER if not EXISTS on_link_insert_add_lookup AFTER INSERT ON link BEGIN insert into search values (NEW.id, NEW.url, NEW.ogTitle, NEW.ogDescription); END;
CREATE TRIGGER if not EXISTS on_link_delete_delete_from_tag_and_category AFTER DELETE ON link BEGIN delete from category_link where link_id = OLD.id; delete from tag_link where link_id = OLD.id; delete from search where id = OLD.id; END;
CREATE TRIGGER if not EXISTS on_category_delete AFTER DELETE ON category BEGIN delete from category_link where category_id = OLD.id; END;
CREATE TRIGGER if not EXISTS on_tag_delete AFTER DELETE ON tag BEGIN delete from tag_link where tag_id = OLD.id; END;
"""

let migrations: [Int32:String] = [
    1674682062: migration_1674682062
]

func getMigrations(lastrun: Int32) -> [String] {
    Array(migrations.filter { i, stmt in i > lastrun }.map { $1 })
}
