pragma user_version=1;

create table if not exists category(
    id      text not null unique,
    name    varchar(50) not null unique,
    icon    varchar(50) not null,
    color   char(6) not null
);

create table if not exists tag(
    id            text not null unique,
    name          varchar(50) not null unique,
    color         char(6) not null
);

create table if not exists link(
    id              text not null unique,
    url             text not null unique,
    starred         bool not null,
    unread          bool not null,
    note            text,
    color           char(7) not null,
    ogTitle         text,
    ogDescription   text,
    ogImageUrl      text,
    created_at      integer not null,
    updated_at      integer not null
);

create table if not exists category_link(
    link_id       text not null references link(id) on delete cascade,
    category_id   text not null references category(id) on delete cascade,
    primary key (link_id, category_id)
);

create table if not exists tag_link(
    link_id   text not null references link(id) on delete cascade,
    tag_id    text not null references tag(id) on delete cascade,
    primary key (link_id, tag_id)
);
