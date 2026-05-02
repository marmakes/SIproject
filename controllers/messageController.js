import { supabase } from '../config/supabaseClient.js'

export const sendMessage = async (req, res) => {
  const { receiver_id, message } = req.body

  const { data, error } = await supabase
    .from('messages')
    .insert([
      {
        sender_id: req.user.id,
        receiver_id,
        message
      }
    ])

  if (error) return res.status(400).json(error)
  res.json(data)
}

export const getMessages = async (req, res) => {
  const userId = req.user.id

  const { data, error } = await supabase
    .from('messages')
    .select('*')
    .or(`sender_id.eq.${userId},receiver_id.eq.${userId}`)

  if (error) return res.status(500).json(error)
  res.json(data)
}