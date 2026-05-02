import express from 'express'
import { createCase, getCases } from '../controllers/caseController.js'
import { verifyUser } from '../middleware/authMiddleware.js'

const router = express.Router()

router.post('/', verifyUser, createCase)
router.get('/', verifyUser, getCases)

export default router