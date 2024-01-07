extern crate rocket;
use rocket::{launch, routes};
pub mod dtos;
pub mod models;
pub mod schema;
mod services;

#[launch]
fn rocket() -> _ {
    rocket::build()
        .mount(
            "/api",
            routes![
                services::get_types_basic,
                services::get_types_full,
                services::get_all,
                services::insert,
                services::get_by_id,
                services::update,
                services::delete,
                services::get_reading_history
            ],
        )
        .mount("/", routes![services::echo_channel])
}
