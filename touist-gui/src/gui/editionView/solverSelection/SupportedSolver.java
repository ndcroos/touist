/*
 *
 * Project TouIST, 2015. Easily formalize and solve real-world sized problems
 * using propositional logic and linear theory of reals with a nice GUI.
 *
 * https://github.com/olzd/touist
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the GNU Lesser General Public License
 * (LGPL) version 2.1 which accompanies this distribution, and is available at
 * http://www.gnu.org/licenses/lgpl-2.1.html
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * Contributors:
 *     Alexis Comte, Abdelwahab Heba, Olivier Lezaud,
 *     Skander Ben Slimane, Maël Valais
 *
 */

package gui.editionView.solverSelection;

import solution.BaseDeClauses;
import solution.Solver;
import translation.TranslatorSAT;

/**
 *
 * @author Skander
 */
public enum SupportedSolver {
    SAT ("SAT", "Basic Solver."), 
    SMT ("SMT", "Support Arithmetic operations.");
    
    private String name;
    private String description;

    private SupportedSolver(String name, String description) {
        this.name = name;
        this.description = description;
    }

    public String getName() {
        return name;
    }

    public String getDescription() {
        return description;
    }
    
    // is s needed in parameter ?
    public void solve(BaseDeClauses b, TranslatorSAT t, Solver s) {
        switch(this) {
            case SAT :
                //TODO
                break;
            case SMT :
                //TODO
                break;
            default:
        }
    }
}
