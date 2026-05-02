import express from 'express'
import { getAllAdvocates, createAdvocateProfile } from '../controllers/advocateController.js'
import { verifyUser } from '../middleware/authMiddleware.js'

const router = express.Router()

router.get('/', getAllAdvocates)
router.post('/', verifyUser, createAdvocateProfile)

export default router