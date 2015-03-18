/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package gui.resultsView;

import entity.Model;
import gui.AbstractComponentPanel;
import gui.State;
import gui.StateV1;

import java.util.ListIterator;

import solution.NotSatisfiableException;
import solution.SolverExecutionException;

/**
 *
 * @author Skander
 */
public class ResultsPanel extends AbstractComponentPanel {

    private int currentModelIndex = 0;
    ListIterator<Model> iter;

    /**
     * Creates new form ResultsPanel
     */
    public ResultsPanel() {
        initComponents();
    }

    /**
     * Update the models iterator
     */
    public void updateIterator() {
        try {
            iter = getFrame().getSolver().getModelList().iterator();
        } catch (NotSatisfiableException | SolverExecutionException e) {
            //TODO gérer proprement l'exception
            e.printStackTrace();
        }
    }

    public void setText(String text) {
        jTextArea1.setText(text);
    }

    /**
     * Enable the next and previous buttons depending on the frame state.
     */
    public void applyRestrictions() {
        switch(getState()) {
            case EDITION :
                // impossible
                break;
            case EDITION_ERROR :
                // impossible
                break;
            case NO_RESULT :
                jButtonNext.setEnabled(false);
                jButtonPrevious.setEnabled(false);
                jTextArea1.setText("Aucune solution n'a été trouvée");
                break;
            case SINGLE_RESULT :
                jButtonNext.setEnabled(false);
                jButtonPrevious.setEnabled(false);
                break;
            case FIRST_RESULT :
                jButtonNext.setEnabled(true);
                jButtonPrevious.setEnabled(false);
                break;
            case INTER_RESULT :
                jButtonNext.setEnabled(true);
                jButtonPrevious.setEnabled(true);
                break;
            case LAST_RESULT :
                jButtonNext.setEnabled(false);
                jButtonPrevious.setEnabled(true);
                break;
            default :
                System.out.println("Undefined action set for the state : " + getState());
        }
    }

    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jLabel1 = new javax.swing.JLabel();
        jButtonEditor = new javax.swing.JButton();
        jButtonPrevious = new javax.swing.JButton();
        jButtonNext = new javax.swing.JButton();
        jScrollPane1 = new javax.swing.JScrollPane();
        jTextArea1 = new javax.swing.JTextArea();

        setMinimumSize(new java.awt.Dimension(400, 300));

        jLabel1.setText("Résultats");

        jButtonEditor.setText("Retour en édition");
        jButtonEditor.addActionListener(new java.awt.event.ActionListener() {
            @Override
			public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonEditorActionPerformed(evt);
            }
        });

        jButtonPrevious.setText("Précédent");
        jButtonPrevious.addActionListener(new java.awt.event.ActionListener() {
            @Override
			public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonPreviousActionPerformed(evt);
            }
        });

        jButtonNext.setText("Suivant");
        jButtonNext.addActionListener(new java.awt.event.ActionListener() {
            @Override
			public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonNextActionPerformed(evt);
            }
        });

        jTextArea1.setEditable(false);
        jTextArea1.setColumns(20);
        jTextArea1.setRows(5);
        jScrollPane1.setViewportView(jTextArea1);

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(jScrollPane1)
                    .addGroup(layout.createSequentialGroup()
                        .addComponent(jLabel1)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, 370, Short.MAX_VALUE)
                        .addComponent(jButtonEditor))
                    .addGroup(layout.createSequentialGroup()
                        .addComponent(jButtonPrevious)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(jButtonNext)
                        .addGap(0, 0, Short.MAX_VALUE)))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel1)
                    .addComponent(jButtonEditor))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 310, Short.MAX_VALUE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jButtonPrevious)
                    .addComponent(jButtonNext))
                .addContainerGap())
        );
    }// </editor-fold>//GEN-END:initComponents

    private void jButtonEditorActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonEditorActionPerformed
        switch(getState()) {
            case EDITION :
                // impossible
                break;
            case EDITION_ERROR :
                // impossible
                break;
            case NO_RESULT :
                getFrame().getSolver().close();
                setState(State.EDITION);
                getFrame().setViewToEditor();
                break;
            case SINGLE_RESULT :
                getFrame().getSolver().close();
                setState(State.EDITION);
                getFrame().setViewToEditor();
                break;
            case FIRST_RESULT :
                getFrame().getSolver().close();
                setState(State.EDITION);
                getFrame().setViewToEditor();
                break;
            case INTER_RESULT :
                getFrame().getSolver().close();
                setState(State.EDITION);
                getFrame().setViewToEditor();
                break;
            case LAST_RESULT :
                getFrame().getSolver().close();
                setState(State.EDITION);
                getFrame().setViewToEditor();
                break;
            default :
                System.out.println("Undefined action set for the state : " + getState());
        }
        getFrame().setViewToEditor();
        this.updateUI();
    }//GEN-LAST:event_jButtonEditorActionPerformed

    /*
    Afficher le model précédent m
    Si m est le premier
    alors on passe à l'état FIRST_RESULT
    sinon à INTER_RESULT
    */
    private State previousButtonHandler() {

        Model m = iter.previous();
        jTextArea1.setText(m.toString());
        if (iter.hasPrevious()) {
            return State.INTER_RESULT;
        } else {
            return State.FIRST_RESULT;
        }
    }

    private void jButtonPreviousActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonPreviousActionPerformed
        Model m;
        switch(getState()) {
            case EDITION :
                // impossible
                break;
            case EDITION_ERROR :
                // impossible
                break;
            case NO_RESULT :
                // interdit
                break;
            case SINGLE_RESULT :
                // interdit
                break;
            case FIRST_RESULT :
                // interdit
                break;
            case INTER_RESULT :
                setState(previousButtonHandler());
                applyRestrictions();
                break;
            case LAST_RESULT :
                setState(previousButtonHandler());
                applyRestrictions();
                break;
            default :
                System.out.println("Undefined action set for the state : " + getState());
        }
        this.updateUI();
    }//GEN-LAST:event_jButtonPreviousActionPerformed

    /*
    Affiche le model suivant m
    si m est le dernier model de models (la liste des models calculés)
    alors demander au solveur de chercher un autre model
        si le solveur ne trouve pas, passe en état LAST_RESULT
        sinon on passe en INTER_RESULT
    */
    private State nextButtonHandler() {
        Model m = iter.next();
        jTextArea1.setText(m.toString());
        if (iter.hasNext()){
            return State.INTER_RESULT;
        } else {
            return State.LAST_RESULT;
        }
    }

    private void jButtonNextActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonNextActionPerformed
        Model m;
        switch(getState()) {
            case EDITION :
                // impossible
                break;
            case EDITION_ERROR :
                // impossible
                break;
            case NO_RESULT :
                // interdit
                break;
            case SINGLE_RESULT :
                // interdit
                break;
            case FIRST_RESULT :
                setState(nextButtonHandler());
                applyRestrictions();
                break;
            case INTER_RESULT :
                setState(nextButtonHandler());
                applyRestrictions();
                break;
            case LAST_RESULT :
                // interdit
                break;
            default :
                System.out.println("Undefined action set for the state : " + getState());
        }
        this.updateUI();
    }//GEN-LAST:event_jButtonNextActionPerformed


    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JButton jButtonEditor;
    private javax.swing.JButton jButtonNext;
    private javax.swing.JButton jButtonPrevious;
    private javax.swing.JLabel jLabel1;
    private javax.swing.JScrollPane jScrollPane1;
    private javax.swing.JTextArea jTextArea1;
    // End of variables declaration//GEN-END:variables
}
