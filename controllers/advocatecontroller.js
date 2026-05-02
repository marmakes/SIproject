import { supabase } from '../config/supabaseClient.js'

export const getAdvocates = async (req, res) => {
  const { data, error } = await supabase
    .from('advocate_profiles')
    .select('*')

  if (error) return res.status(500).json(error)
  res.json(data)
}