import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export interface AuthenticatedRequest extends Request {
  userId?: string;
}

export const authenticateJWT = (req: AuthenticatedRequest, res: Response, next: NextFunction): any => {
  const authHeader = req.headers.authorization;

  if (authHeader) {
    const token = authHeader.split(' ')[1]; // Bearer <token>

    jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret', (err: any, decoded: any) => {
      if (err) {
        return res.sendStatus(403); // Forbidden
      }

      req.userId = decoded.userId;
      next();
    });
  } else {
    res.sendStatus(401); // Unauthorized
  }
};
