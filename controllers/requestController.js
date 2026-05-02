import { supabase } from '../config/supabaseClient.js'

// create request
export const createRequest = async (req, res) => {
  const { advocate_id, subject, estimated_fee } = req.body

  const { data, error } = await supabase
    .from('requests')
    .insert([
      {
        client_id: req.user.id,
        advocate_id,
        subject,
        estimated_fee
      }
    ])

  if (error) return res.status(400).json(error)
  res.json(data)
}

// get requests (client or advocate)
export const getRequests = async (req, res) => {
  const userId = req.user.id

  const { data, error } = await supabase
    .from('requests')
    .select('*')
    .or(`client_id.eq.${userId},advocate_id.eq.${userId}`)

  if (error) return res.status(500).json(error)
  res.json(data)
}

// accept / decline
export const updateRequestStatus = async (req, res) => {
  const { id } = req.params
  const { status } = req.body

  const { data, error } = await supabase
    .from('requests')
    .update({ status })
    .eq('id', id)

  if (error) return res.status(400).json(error)
  res.json(data)
}