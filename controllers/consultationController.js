import { supabase } from '../config/supabaseClient.js'

export const createConsultation = async (req, res) => {
  const { advocate_id, scheduled_time } = req.body

  const { data, error } = await supabase
    .from('appointments')
    .insert([
      {
        client_id: req.user.id,
        advocate_id,
        scheduled_time
      }
    ])

  if (error) return res.status(400).json(error)
  res.json(data)
}