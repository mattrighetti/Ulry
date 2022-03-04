-- Activate foreign keys
PRAGMA foreign_keys = ON;
PRAGMA user_version = 1;

create table group(
    id      text unique,
    name    varchar(50) not null unique,
    icon    varchar(50) not null,
    color   char(6) not null
);

create table tag(
    id            text unique,
    name          varchar(50) not null unique,
    description   text,
    color         char(6) not null
);

create table link(
    id              text unique,
    url             text not null,
    starred         bool not null,
    unread          bool not null,
    note            text,
    color           char(6) not null,
    image           text,
    ogImage         text,
    ogDescription   text,
    ogImageUrl      text
    created_at      integer not null,
    updated_at      integer not null
);

create table folder_link(
    link_id       text not null references link(id) on delete cascade,
    folder_id     text not null references group(id) on delete cascade,
    primary key (link_id, group_id)
);

create table tag_link(
    link_id       text not null references link(id) on delete cascade,
    tag_id        text not null references tag(id) on delete cascade,
    primary key (link_id, tag_id)
);
