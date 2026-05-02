import express from 'express'
import { sendMessage, getMessages } from '../controllers/messageController.js'
import { verifyUser } from '../middleware/authMiddleware.js'

const router = express.Router()

router.post('/', verifyUser, sendMessage)
router.get('/', verifyUser, getMessages)

export default router