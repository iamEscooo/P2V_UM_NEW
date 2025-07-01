namespace P2V_UM_2
{
    partial class Select_user
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.u_label = new System.Windows.Forms.Label();
            this.u_input = new System.Windows.Forms.TextBox();
            this.Radio1 = new System.Windows.Forms.RadioButton();
            this.radioButton2 = new System.Windows.Forms.RadioButton();
            this.u_search_button = new System.Windows.Forms.Button();
            this.okbutton = new System.Windows.Forms.Button();
            this.Userinfo = new System.Windows.Forms.TextBox();
            this.cancelbutton = new System.Windows.Forms.Button();
            this.SuspendLayout();
            // 
            // u_label
            // 
            this.u_label.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.u_label.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.u_label.Location = new System.Drawing.Point(5, 15);
            this.u_label.Name = "u_label";
            this.u_label.Size = new System.Drawing.Size(197, 20);
            this.u_label.TabIndex = 0;
            this.u_label.Text = "enter xkey or searchstring: ";
            this.u_label.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // u_input
            // 
            this.u_input.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.u_input.Location = new System.Drawing.Point(200, 15);
            this.u_input.Name = "u_input";
            this.u_input.Size = new System.Drawing.Size(175, 20);
            this.u_input.TabIndex = 1;
            this.u_input.Text = "<user - xkey>";
            // 
            // Radio1
            // 
            this.Radio1.AutoSize = true;
            this.Radio1.Checked = true;
            this.Radio1.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.Radio1.Location = new System.Drawing.Point(45, 50);
            this.Radio1.Name = "Radio1";
            this.Radio1.Size = new System.Drawing.Size(63, 17);
            this.Radio1.TabIndex = 2;
            this.Radio1.TabStop = true;
            this.Radio1.Text = "from AD";
            this.Radio1.UseVisualStyleBackColor = true;
            // 
            // radioButton2
            // 
            this.radioButton2.AutoSize = true;
            this.radioButton2.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.radioButton2.Location = new System.Drawing.Point(117, 50);
            this.radioButton2.Name = "radioButton2";
            this.radioButton2.Size = new System.Drawing.Size(68, 17);
            this.radioButton2.TabIndex = 3;
            this.radioButton2.Text = "from P2V";
            this.radioButton2.UseVisualStyleBackColor = true;
            // 
            // u_search_button
            // 
            this.u_search_button.Location = new System.Drawing.Point(200, 45);
            this.u_search_button.Name = "u_search_button";
            this.u_search_button.Size = new System.Drawing.Size(140, 25);
            this.u_search_button.TabIndex = 4;
            this.u_search_button.Text = "search user";
            this.u_search_button.UseVisualStyleBackColor = true;
            // 
            // okbutton
            // 
            this.okbutton.Location = new System.Drawing.Point(15, 195);
            this.okbutton.Name = "okbutton";
            this.okbutton.Size = new System.Drawing.Size(140, 25);
            this.okbutton.TabIndex = 5;
            this.okbutton.Text = "continue";
            this.okbutton.UseVisualStyleBackColor = true;
            // 
            // Userinfo
            // 
            this.Userinfo.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.Userinfo.Font = new System.Drawing.Font("Lucida Console", 9F);
            this.Userinfo.Location = new System.Drawing.Point(15, 80);
            this.Userinfo.Multiline = true;
            this.Userinfo.Name = "Userinfo";
            this.Userinfo.ReadOnly = true;
            this.Userinfo.Size = new System.Drawing.Size(370, 110);
            this.Userinfo.TabIndex = 6;
            // 
            // cancelbutton
            // 
            this.cancelbutton.Location = new System.Drawing.Point(245, 195);
            this.cancelbutton.Name = "cancelbutton";
            this.cancelbutton.Size = new System.Drawing.Size(140, 25);
            this.cancelbutton.TabIndex = 7;
            this.cancelbutton.Text = "Exit";
            this.cancelbutton.UseVisualStyleBackColor = true;
            // 
            // Select_user
            // 
            this.AcceptButton = this.okbutton;
            this.AutoScaleDimensions = new System.Drawing.SizeF(8F, 16F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(401, 227);
            this.Controls.Add(this.cancelbutton);
            this.Controls.Add(this.Userinfo);
            this.Controls.Add(this.okbutton);
            this.Controls.Add(this.u_search_button);
            this.Controls.Add(this.radioButton2);
            this.Controls.Add(this.Radio1);
            this.Controls.Add(this.u_input);
            this.Controls.Add(this.u_label);
            this.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.Margin = new System.Windows.Forms.Padding(4, 4, 4, 4);
            this.Name = "Select_user";
            this.Text = "select user";
            this.Load += new System.EventHandler(this.Select_user_Load);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label u_label;
        private System.Windows.Forms.TextBox u_input;
        private System.Windows.Forms.RadioButton Radio1;
        private System.Windows.Forms.RadioButton radioButton2;
        private System.Windows.Forms.Button u_search_button;
        private System.Windows.Forms.Button okbutton;
        private System.Windows.Forms.TextBox Userinfo;
        private System.Windows.Forms.Button cancelbutton;
    }
}