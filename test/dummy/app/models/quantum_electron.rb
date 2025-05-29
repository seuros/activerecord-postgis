# frozen_string_literal: true

# == Schema Information
#
# Table name: quantum_electrons
#
#  id           :string           not null, primary key
#  spin_state   :string           not null, comment: "Electron spin: up or down"
#  energy_shell :integer          comment: "Which electron shell (1, 2, 3, etc.)"
#  atom_id      :string           comment: "Which atom contains this electron"
#  charge       :float            default: -1.0, comment: "Electric charge (always negative)"
#  paired       :boolean          default: false, comment: "Is electron paired with another?"
#  created_at   :datetime         not null, comment: "Classical time tracking"
#  updated_at   :datetime         not null, comment: "Classical time tracking"
#

# Quantum electrons orbiting in the SQLite atomic dimension ⚛️
# These negatively charged particles exist in discrete energy shells
class QuantumElectron < QuantumParticle
  validates :spin_state, presence: true, inclusion: { in: %w[up down] }
  validates :energy_shell, numericality: { greater_than: 0 }, allow_nil: true
  validates :charge, numericality: { equal_to: -1.0 }

  scope :spin_up, -> { where(spin_state: 'up') }
  scope :spin_down, -> { where(spin_state: 'down') }
  scope :unpaired, -> { where(paired: false) }
  scope :in_shell, ->(shell) { where(energy_shell: shell) }
  scope :valence, -> { where(energy_shell: [3, 4, 5, 6, 7]) }

  # Electrons follow Pauli exclusion principle even in SQLite! 🚫
  def self.max_electrons_in_shell(shell_number)
    2 * (shell_number ** 2)
  end

  def orbital_radius
    return nil unless energy_shell.present?
    # Bohr radius approximation in picometers
    52.9 * (energy_shell ** 2) 
  end

  def can_pair_with?(other_electron)
    return false unless other_electron.is_a?(QuantumElectron)
    return false if spin_state == other_electron.spin_state
    energy_shell == other_electron.energy_shell && !paired && !other_electron.paired
  end
end