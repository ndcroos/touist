/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package gui.menu;

import gui.AbstractComponentPanel;
import gui.Lang;
import gui.MainFrame;
import gui.SolverSelection;
import java.io.File;
import java.util.Locale;
import javax.swing.JDialog;
import javax.swing.JFileChooser;

/**
 *
 * @author Skander
 */
public class SettingsPanel extends AbstractComponentPanel {

    /*
    Adding items in jComboBoxLanguages launches an ActionEvent,
    to prevent that, we will set jComboBoxLanguagesEnable to true
    once all items are added.
     */
    private boolean jComboBoxLanguagesEnabled = false;
    
    public SettingsPanel(MainFrame parent) {
        initComponents();
        
        this.parent = parent;
        updateLanguage();
        
        buttonGroup1.add(jRadioButtonSAT4J);
        buttonGroup1.add(jRadioButtonYCES);
        buttonGroup2.add(jRadioButtonSMTLQFLRA);
        buttonGroup2.add(jRadioButtonSMTLQFLIA);
        buttonGroup2.add(jRadioButtonSMTLQFRDL);
        buttonGroup2.add(jRadioButtonSMTLQFIDL);
        
        switch(parent.getSolverSelection().getSelectedSolver()) {
            case SAT4J : 
                jRadioButtonSAT4J.setSelected(true);
                break;
            case SMT_QF_LRA : 
                jRadioButtonYCES.setSelected(true);
                jRadioButtonSMTLQFLRA.setSelected(true);
                break;
            case SMT_QF_LIA : 
                jRadioButtonYCES.setSelected(true);
                jRadioButtonSMTLQFLIA.setSelected(true);
                break;
            case SMT_QF_RDL : 
                jRadioButtonYCES.setSelected(true);
                jRadioButtonSMTLQFRDL.setSelected(true);
                break;
            case SMT_QF_IDL : 
                jRadioButtonYCES.setSelected(true);
                jRadioButtonSMTLQFIDL.setSelected(true);
                break;
            default :
        }
        updateRadioButtons();
        
        jComboBoxLanguages.removeAllItems();
        for (Locale locale : parent.getLang().getSupportedLanguages()) {
            jComboBoxLanguages.addItem(locale);
        }
        jComboBoxLanguagesEnabled = true; 
        jComboBoxLanguages.setSelectedItem(parent.getLang().getLanguage());
    }
    
    private MainFrame parent = null;
    
    /**
     * Creates new form Settings
     */
    public SettingsPanel() {
        initComponents();
        
        buttonGroup1.add(jRadioButtonSAT4J);
        buttonGroup1.add(jRadioButtonYCES);
        buttonGroup2.add(jRadioButtonSMTLQFLRA);
        buttonGroup2.add(jRadioButtonSMTLQFLIA);
        buttonGroup2.add(jRadioButtonSMTLQFRDL);
        buttonGroup2.add(jRadioButtonSMTLQFIDL);
        updateRadioButtons();
        
        jComboBoxLanguages.removeAllItems();
        for (Locale locale : parent.getLang().getSupportedLanguages()) {
            jComboBoxLanguages.addItem(locale);
        }
    }
    
    public void updateRadioButtons() {
        jRadioButtonSMTLQFLRA.setEnabled(! jRadioButtonSAT4J.isSelected());
        jRadioButtonSMTLQFLIA.setEnabled(! jRadioButtonSAT4J.isSelected());
        jRadioButtonSMTLQFRDL.setEnabled(! jRadioButtonSAT4J.isSelected());
        jRadioButtonSMTLQFIDL.setEnabled(! jRadioButtonSAT4J.isSelected());
        updateUI();
    }
    

    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        buttonGroup1 = new javax.swing.ButtonGroup();
        buttonGroup2 = new javax.swing.ButtonGroup();
        jTabbedPane1 = new javax.swing.JTabbedPane();
        jPanelGeneral = new javax.swing.JPanel();
        jLabelDefaultDirectory = new javax.swing.JLabel();
        jTextFieldPath = new javax.swing.JTextField();
        jButtonChangeDirectory = new javax.swing.JButton();
        jPanelSolver = new javax.swing.JPanel();
        jRadioButtonSAT4J = new javax.swing.JRadioButton();
        jRadioButtonYCES = new javax.swing.JRadioButton();
        jRadioButtonSMTLQFLRA = new javax.swing.JRadioButton();
        jRadioButtonSMTLQFLIA = new javax.swing.JRadioButton();
        jRadioButtonSMTLQFRDL = new javax.swing.JRadioButton();
        jRadioButtonSMTLQFIDL = new javax.swing.JRadioButton();
        jLabelSolver = new javax.swing.JLabel();
        jPanelLanguage = new javax.swing.JPanel();
        jLabelLanguage = new javax.swing.JLabel();
        jComboBoxLanguages = new javax.swing.JComboBox();

        jLabelDefaultDirectory.setText("Default directory");

        jTextFieldPath.setEditable(false);
        jTextFieldPath.setText("path");

        jButtonChangeDirectory.setText("Change");
        jButtonChangeDirectory.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonChangeDirectoryActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout jPanelGeneralLayout = new javax.swing.GroupLayout(jPanelGeneral);
        jPanelGeneral.setLayout(jPanelGeneralLayout);
        jPanelGeneralLayout.setHorizontalGroup(
            jPanelGeneralLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanelGeneralLayout.createSequentialGroup()
                .addContainerGap()
                .addGroup(jPanelGeneralLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(jPanelGeneralLayout.createSequentialGroup()
                        .addComponent(jLabelDefaultDirectory)
                        .addGap(0, 0, Short.MAX_VALUE))
                    .addGroup(jPanelGeneralLayout.createSequentialGroup()
                        .addComponent(jTextFieldPath, javax.swing.GroupLayout.DEFAULT_SIZE, 279, Short.MAX_VALUE)
                        .addGap(18, 18, 18)
                        .addComponent(jButtonChangeDirectory)))
                .addContainerGap())
        );
        jPanelGeneralLayout.setVerticalGroup(
            jPanelGeneralLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanelGeneralLayout.createSequentialGroup()
                .addContainerGap()
                .addComponent(jLabelDefaultDirectory)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(jPanelGeneralLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jTextFieldPath, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(jButtonChangeDirectory))
                .addContainerGap(151, Short.MAX_VALUE))
        );

        jTabbedPane1.addTab("General", jPanelGeneral);

        jRadioButtonSAT4J.setSelected(true);
        jRadioButtonSAT4J.setText("SAT4J");
        jRadioButtonSAT4J.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jRadioButtonSAT4JActionPerformed(evt);
            }
        });

        jRadioButtonYCES.setText("YCES");
        jRadioButtonYCES.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jRadioButtonYCESActionPerformed(evt);
            }
        });

        jRadioButtonSMTLQFLRA.setText("SMT_QF_LRA");
        jRadioButtonSMTLQFLRA.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jRadioButtonSMTLQFLRAActionPerformed(evt);
            }
        });

        jRadioButtonSMTLQFLIA.setText("SMT_QF_LIA");
        jRadioButtonSMTLQFLIA.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jRadioButtonSMTLQFLIAActionPerformed(evt);
            }
        });

        jRadioButtonSMTLQFRDL.setText("SMT_QF_RDL");
        jRadioButtonSMTLQFRDL.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jRadioButtonSMTLQFRDLActionPerformed(evt);
            }
        });

        jRadioButtonSMTLQFIDL.setText("SMT_QF_IDL");
        jRadioButtonSMTLQFIDL.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jRadioButtonSMTLQFIDLActionPerformed(evt);
            }
        });

        jLabelSolver.setText("Choose your solver");

        javax.swing.GroupLayout jPanelSolverLayout = new javax.swing.GroupLayout(jPanelSolver);
        jPanelSolver.setLayout(jPanelSolverLayout);
        jPanelSolverLayout.setHorizontalGroup(
            jPanelSolverLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanelSolverLayout.createSequentialGroup()
                .addContainerGap()
                .addGroup(jPanelSolverLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(jPanelSolverLayout.createSequentialGroup()
                        .addGap(21, 21, 21)
                        .addGroup(jPanelSolverLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(jRadioButtonSMTLQFRDL)
                            .addComponent(jRadioButtonSMTLQFLIA)
                            .addComponent(jRadioButtonSMTLQFLRA)
                            .addComponent(jRadioButtonSMTLQFIDL)))
                    .addComponent(jRadioButtonSAT4J)
                    .addComponent(jRadioButtonYCES)
                    .addComponent(jLabelSolver))
                .addContainerGap(264, Short.MAX_VALUE))
        );
        jPanelSolverLayout.setVerticalGroup(
            jPanelSolverLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, jPanelSolverLayout.createSequentialGroup()
                .addContainerGap()
                .addComponent(jLabelSolver)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addComponent(jRadioButtonSAT4J)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jRadioButtonYCES)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addComponent(jRadioButtonSMTLQFLRA)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addComponent(jRadioButtonSMTLQFLIA)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jRadioButtonSMTLQFRDL)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jRadioButtonSMTLQFIDL)
                .addContainerGap(29, Short.MAX_VALUE))
        );

        jTabbedPane1.addTab("Solver", jPanelSolver);

        jLabelLanguage.setText("Language");

        jComboBoxLanguages.setModel(new javax.swing.DefaultComboBoxModel(new String[] { "Item 1", "Item 2", "Item 3", "Item 4" }));
        jComboBoxLanguages.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jComboBoxLanguagesActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout jPanelLanguageLayout = new javax.swing.GroupLayout(jPanelLanguage);
        jPanelLanguage.setLayout(jPanelLanguageLayout);
        jPanelLanguageLayout.setHorizontalGroup(
            jPanelLanguageLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanelLanguageLayout.createSequentialGroup()
                .addContainerGap()
                .addComponent(jLabelLanguage)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, 78, Short.MAX_VALUE)
                .addComponent(jComboBoxLanguages, javax.swing.GroupLayout.PREFERRED_SIZE, 128, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addContainerGap(123, Short.MAX_VALUE))
        );
        jPanelLanguageLayout.setVerticalGroup(
            jPanelLanguageLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanelLanguageLayout.createSequentialGroup()
                .addContainerGap()
                .addGroup(jPanelLanguageLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabelLanguage)
                    .addComponent(jComboBoxLanguages, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addContainerGap(174, Short.MAX_VALUE))
        );

        jTabbedPane1.addTab("Language", jPanelLanguage);

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addComponent(jTabbedPane1, javax.swing.GroupLayout.PREFERRED_SIZE, 391, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addGap(0, 0, Short.MAX_VALUE))
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addComponent(jTabbedPane1, javax.swing.GroupLayout.PREFERRED_SIZE, 233, javax.swing.GroupLayout.PREFERRED_SIZE)
        );

        jTabbedPane1.getAccessibleContext().setAccessibleName("General");
    }// </editor-fold>//GEN-END:initComponents

    private void jButtonChangeDirectoryActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonChangeDirectoryActionPerformed
        JFileChooser jFileChooser = new JFileChooser(new File(parent.getDefaultDirectoryPath()));
        jFileChooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
        int returnVal = jFileChooser.showOpenDialog(this);
        
        if (returnVal == JFileChooser.APPROVE_OPTION && jFileChooser.getSelectedFile() != null) {
            String path = jFileChooser.getSelectedFile().getPath();
            jTextFieldPath.setText(path);
            parent.setDefaultDirectoryPath(path);
        }
        
    }//GEN-LAST:event_jButtonChangeDirectoryActionPerformed

    private void jComboBoxLanguagesActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jComboBoxLanguagesActionPerformed
        if (jComboBoxLanguagesEnabled && jComboBoxLanguages.getSelectedIndex() >= 0) {
            Locale selectedLanguage = (Locale)jComboBoxLanguages.getSelectedItem();
            parent.setLanguage(selectedLanguage);
            parent.updateLanguage();
            updateLanguage();
        }
    }//GEN-LAST:event_jComboBoxLanguagesActionPerformed

    private void jRadioButtonSAT4JActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jRadioButtonSAT4JActionPerformed
        parent.getSolverSelection().setSelectedSolver(SolverSelection.SolverType.SAT4J);
        jRadioButtonSMTLQFLRA.setSelected(false);
        jRadioButtonSMTLQFLIA.setSelected(false);
        jRadioButtonSMTLQFRDL.setSelected(false);
        jRadioButtonSMTLQFIDL.setSelected(false);
        updateRadioButtons();
    }//GEN-LAST:event_jRadioButtonSAT4JActionPerformed

    private void jRadioButtonYCESActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jRadioButtonYCESActionPerformed
        parent.getSolverSelection().setSelectedSolver(SolverSelection.SolverType.SMT_QF_LRA);
        jRadioButtonSMTLQFLRA.setSelected(true);
        updateRadioButtons();
    }//GEN-LAST:event_jRadioButtonYCESActionPerformed

    private void jRadioButtonSMTLQFLIAActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jRadioButtonSMTLQFLIAActionPerformed
        parent.getSolverSelection().setSelectedSolver(SolverSelection.SolverType.SMT_QF_LIA);
        updateRadioButtons();
    }//GEN-LAST:event_jRadioButtonSMTLQFLIAActionPerformed

    private void jRadioButtonSMTLQFLRAActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jRadioButtonSMTLQFLRAActionPerformed
        parent.getSolverSelection().setSelectedSolver(SolverSelection.SolverType.SMT_QF_LRA);
        updateRadioButtons();
    }//GEN-LAST:event_jRadioButtonSMTLQFLRAActionPerformed

    private void jRadioButtonSMTLQFRDLActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jRadioButtonSMTLQFRDLActionPerformed
        parent.getSolverSelection().setSelectedSolver(SolverSelection.SolverType.SMT_QF_RDL);
        updateRadioButtons();
    }//GEN-LAST:event_jRadioButtonSMTLQFRDLActionPerformed

    private void jRadioButtonSMTLQFIDLActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jRadioButtonSMTLQFIDLActionPerformed
        parent.getSolverSelection().setSelectedSolver(SolverSelection.SolverType.SMT_QF_IDL);
        updateRadioButtons();
    }//GEN-LAST:event_jRadioButtonSMTLQFIDLActionPerformed


    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.ButtonGroup buttonGroup1;
    private javax.swing.ButtonGroup buttonGroup2;
    private javax.swing.JButton jButtonChangeDirectory;
    private javax.swing.JComboBox jComboBoxLanguages;
    private javax.swing.JLabel jLabelDefaultDirectory;
    private javax.swing.JLabel jLabelLanguage;
    private javax.swing.JLabel jLabelSolver;
    private javax.swing.JPanel jPanelGeneral;
    private javax.swing.JPanel jPanelLanguage;
    private javax.swing.JPanel jPanelSolver;
    private javax.swing.JRadioButton jRadioButtonSAT4J;
    private javax.swing.JRadioButton jRadioButtonSMTLQFIDL;
    private javax.swing.JRadioButton jRadioButtonSMTLQFLIA;
    private javax.swing.JRadioButton jRadioButtonSMTLQFLRA;
    private javax.swing.JRadioButton jRadioButtonSMTLQFRDL;
    private javax.swing.JRadioButton jRadioButtonYCES;
    private javax.swing.JTabbedPane jTabbedPane1;
    private javax.swing.JTextField jTextFieldPath;
    // End of variables declaration//GEN-END:variables

    @Override
    public void updateLanguage() {
        if (getParent() != null && getRootPane().getParent() instanceof JDialog) {
            ((JDialog)(getRootPane().getParent())).setTitle(parent.getLang().getWord(Lang.SETTINGS_TITLE));
        }
        jTabbedPane1.setTitleAt(0, parent.getLang().getWord(Lang.SETTINGS_GENERAL_TITLE));
        jTabbedPane1.setTitleAt(1, parent.getLang().getWord(Lang.SETTINGS_SOLVER_TITLE));
        jTabbedPane1.setTitleAt(2, parent.getLang().getWord(Lang.SETTINGS_LANGUAGE_TITLE));
        jLabelDefaultDirectory.setText(parent.getLang().getWord(Lang.SETTINGS_GENERAL_TEXT));
        jButtonChangeDirectory.setText(parent.getLang().getWord(Lang.SETTINGS_GENERAL_BUTTON));
        jLabelSolver.setText(parent.getLang().getWord(Lang.SETTINGS_SOLVER_TEXT));
        jLabelLanguage.setText(parent.getLang().getWord(Lang.SETTINGS_LANGUAGE_TEXT));
    }
}
