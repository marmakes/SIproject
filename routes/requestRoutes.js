import express from 'express'
import { createRequest, getRequests, updateRequestStatus } from '../controllers/requestController.js'
import { verifyUser } from '../middleware/authMiddleware.js'

const router = express.Router()

router.post('/', verifyUser, createRequest)
router.get('/', verifyUser, getRequests)
router.patch('/:id', verifyUser, updateRequestStatus)

export default router