Facter.add(:agent_pid) do
  setcode { Process.pid }
end
