import { supabase } from '../config/supabaseClient.js'

export const signUp = async (req, res) => {
  const { email, password } = req.body

  const { data, error } = await supabase.auth.signUp({ email, password })

  if (error) return res.status(400).json(error)
  res.json(data)
}

export const login = async (req, res) => {
  const { email, password } = req.body

  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  })

  if (error) return res.status(400).json(error)
  res.json(data)
}