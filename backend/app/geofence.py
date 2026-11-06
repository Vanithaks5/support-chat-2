"""Office geofence calculations."""
from math import asin, cos, radians, sin, sqrt

from .config import OFFICE_LATITUDE, OFFICE_LONGITUDE, OFFICE_RADIUS_METERS


def is_out_of_office(latitude: float | None, longitude: float | None) -> bool:
    """Return True when coordinates are missing or outside the office radius."""
    if latitude is None or longitude is None:
        return True

    earth_radius_meters = 6_371_000
    lat1, lat2 = radians(OFFICE_LATITUDE), radians(latitude)
    delta_lat = radians(latitude - OFFICE_LATITUDE)
    delta_lon = radians(longitude - OFFICE_LONGITUDE)
    a = sin(delta_lat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(delta_lon / 2) ** 2
    distance = earth_radius_meters * 2 * asin(sqrt(a))
    return distance > OFFICE_RADIUS_METERS
