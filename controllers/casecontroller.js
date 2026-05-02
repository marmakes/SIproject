import { supabase } from '../config/supabaseClient.js'

export const createCase = async (req, res) => {
  const { title, description, client_id } = req.body
  const advocate_id = req.user.id

  const { data, error } = await supabase
    .from('cases')
    .insert([
      { title, description, client_id, advocate_id }
    ])

  if (error) return res.status(400).json(error)
  res.json(data)
}

export const getCases = async (req, res) => {
  const { data, error } = await supabase
    .from('cases')
    .select('*')

  if (error) return res.status(500).json(error)
  res.json(data)
}