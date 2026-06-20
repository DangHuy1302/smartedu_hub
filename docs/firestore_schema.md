# Firestore Schema for SmartEdu Hub (Module: Booking)

This document describes the collections used by the Booking module implemented by Bùi Gia Hiếu.

## Collection: rooms
- Document ID: string (auto or slug)
- Fields:
  - name: string
  - lat: double
  - lng: double
  - totalSeats: int
  - availableSeats: int
  - description: string (optional)
  - createdAt: ISO8601 string

Example document:
```
{
  "name": "Thư viện Cơ sở A",
  "lat": 21.0065,
  "lng": 105.8428,
  "totalSeats": 30,
  "availableSeats": 30,
  "description": "Thư viện tầng 1",
  "createdAt": "2026-06-01T00:00:00.000Z"
}
```

## Collection: bookings
- Document ID: string (auto)
- Fields:
  - roomId: string (reference to rooms doc id)
  - userId: string
  - userName: string
  - createdAt: ISO8601 string
  - status: string (e.g., 'active', 'canceled')

Example document:
```
{
  "roomId": "room_abc123",
  "userId": "uid_123",
  "userName": "Nguyen Van A",
  "createdAt": "2026-06-10T09:12:00.000Z",
  "status": "active"
}
```

## Notes
- Use Firestore transactions when decrementing `availableSeats` to avoid overbooking.
- For development you can seed a few `rooms` documents using `docs/rooms_seed.json` (to be added).
