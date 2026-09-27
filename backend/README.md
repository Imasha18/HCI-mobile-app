# Table & Hearth API

Express and MongoDB backend for the Table & Hearth local-food marketplace.

## Setup

```bash
cd backend
npm install
cp .env.example .env
npm run dev
```

The API defaults to `http://localhost:5000` and exposes `GET /api/health`.

## API groups

- `/api/auth`: registration, login, and current user
- `/api/meals`: public meal discovery and cook meal creation
- `/api/orders`, `/api/cart`, `/api/payments`, `/api/reviews`
- `/api/customers`, `/api/cooks`, `/api/riders`, `/api/deliveries`
- `/api/notifications`, `/api/admin`

MongoDB is configured through `MONGO_URI`. Cloudinary and Firebase settings are optional until their integrations are enabled.
