use super::schema::{plants, types};
use diesel::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Queryable, Insertable, Serialize, Deserialize, Selectable)]
#[diesel(table_name = plants)]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct Plant {
    pub id: String,
    pub plant_name: String,
    pub type_id: String,
}

#[derive(Queryable, Insertable, Serialize, Deserialize, Selectable)]
#[diesel(table_name = types)]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct Type {
    pub id: String,
    pub type_name: String,
    pub light_intensity_need: f64,
    pub soil_moisture_need: i32,
    pub temperature_need: f64,
    pub humidity_need: f64,
    pub pressure_need: f64,
}
