-- Your SQL goes here
CREATE TABLE types(
    id VARCHAR PRIMARY KEY,
    type_name VARCHAR NOT NULL UNIQUE,
    light_intensity_need FLOAT NOT NULL,
    soil_moisture_need INTEGER NOT NULL,
    temperature_need FLOAT NOT NULL,
    humidity_need FLOAT NOT NULL,
    pressure_need FLOAT NOT NULL
);

INSERT INTO types VALUES (1,'Yucca', 2000.0, 50,23.0,80.0,1013.4),
                         (2,'Cactus', 4000.0, 20,25.0,20.0,1013.4),
                         (3,'Succulent', 3000.0, 30,22.5,65.0,1013.4),
                         (4,'Bonsai', 2000.0, 45,24.5,71.0,1013.4),
                         (5,'Palm', 4000.0, 70,19.0,90.0,1013.4);

CREATE TABLE plants (
  id VARCHAR PRIMARY KEY,
  plant_name VARCHAR NOT NULL UNIQUE,
  type_id VARCHAR NOT NULL,
  FOREIGN KEY (type_id) REFERENCES types(id)
)