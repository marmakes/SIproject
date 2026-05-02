import express from 'express'
import { createConsultation } from '../controllers/consultationController.js'
import { verifyUser } from '../middleware/authMiddleware.js'

const router = express.Router()

router.post('/', verifyUser, createConsultation)

export default router