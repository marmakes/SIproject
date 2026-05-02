import express from 'express'
import cors from 'cors'

import authRoutes from './routes/authRoutes.js'
import requestRoutes from './routes/requestRoutes.js'
import consultationRoutes from './routes/consultationRoutes.js'
import messageRoutes from './routes/messageRoutes.js'

const app = express()

app.use(cors())
app.use(express.json())

app.use('/api/auth', authRoutes)
app.use('/api/requests', requestRoutes)
app.use('/api/consultations', consultationRoutes)
app.use('/api/messages', messageRoutes)

export default app