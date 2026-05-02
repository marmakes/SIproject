import { supabase } from '../config/supabaseClient.js'

export const getClients = async (req, res) => {
  const { data, error } = await supabase
    .from('clients')
    .select('*')

  if (error) return res.status(500).json(error)
  res.json(data)
}