// @generated automatically by Diesel CLI.

diesel::table! {
    plants (id) {
        id -> Varchar,
        plant_name -> Varchar,
        type_id -> Varchar,
    }
}

diesel::table! {
    types (id) {
        id -> Varchar,
        type_name -> Varchar,
        light_intensity_need -> Float8,
        soil_moisture_need -> Int4,
        temperature_need -> Float8,
        humidity_need -> Float8,
        pressure_need -> Float8,
    }
}

diesel::joinable!(plants -> types (type_id));

diesel::allow_tables_to_appear_in_same_query!(
    plants,
    types,
);
