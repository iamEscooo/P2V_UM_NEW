namespace P2V_UM_2
{
    partial class Main
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Main));
            this.Logo = new System.Windows.Forms.PictureBox();
            this.Title = new System.Windows.Forms.Label();
            this.UsageInfo = new System.Windows.Forms.TextBox();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.groupBox2 = new System.Windows.Forms.GroupBox();
            this.selected_user = new System.Windows.Forms.TextBox();
            this.button1 = new System.Windows.Forms.Button();
            this.button2 = new System.Windows.Forms.Button();
            this.button3 = new System.Windows.Forms.Button();
            this.button4 = new System.Windows.Forms.Button();
            this.button5 = new System.Windows.Forms.Button();
            this.button6 = new System.Windows.Forms.Button();
            this.button7 = new System.Windows.Forms.Button();
            this.button8 = new System.Windows.Forms.Button();
            this.button9 = new System.Windows.Forms.Button();
            this.button10 = new System.Windows.Forms.Button();
            this.button11 = new System.Windows.Forms.Button();
            this.button12 = new System.Windows.Forms.Button();
            this.button13 = new System.Windows.Forms.Button();
            this.button14 = new System.Windows.Forms.Button();
            this.button15 = new System.Windows.Forms.Button();
            this.button16 = new System.Windows.Forms.Button();
            this.button17 = new System.Windows.Forms.Button();
            this.button18 = new System.Windows.Forms.Button();
            this.button19 = new System.Windows.Forms.Button();
            this.button20 = new System.Windows.Forms.Button();
            this.ExitButton = new System.Windows.Forms.Button();
            this.progressBar1 = new System.Windows.Forms.ProgressBar();
            this.statusfield = new System.Windows.Forms.Label();
            this.textBox1 = new System.Windows.Forms.TextBox();
            this.userinputBox = new System.Windows.Forms.TextBox();
            ((System.ComponentModel.ISupportInitialize)(this.Logo)).BeginInit();
            this.groupBox1.SuspendLayout();
            this.groupBox2.SuspendLayout();
            this.SuspendLayout();
            // 
            // Logo
            // 
            this.Logo.Image = ((System.Drawing.Image)(resources.GetObject("Logo.Image")));
            this.Logo.Location = new System.Drawing.Point(35, 15);
            this.Logo.Name = "Logo";
            this.Logo.Size = new System.Drawing.Size(100, 100);
            this.Logo.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.Logo.TabIndex = 0;
            this.Logo.TabStop = false;
            // 
            // Title
            // 
            this.Title.Font = new System.Drawing.Font("Microsoft Sans Serif", 20F, System.Drawing.FontStyle.Bold);
            this.Title.Location = new System.Drawing.Point(175, 20);
            this.Title.Name = "Title";
            this.Title.Size = new System.Drawing.Size(400, 100);
            this.Title.TabIndex = 1;
            this.Title.Text = "Plan2Value Usermanagement\r\n -- single user mode -- \r\n";
            // 
            // UsageInfo
            // 
            this.UsageInfo.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.UsageInfo.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.UsageInfo.Font = new System.Drawing.Font("Microsoft Sans Serif", 8F);
            this.UsageInfo.Location = new System.Drawing.Point(20, 760);
            this.UsageInfo.Name = "UsageInfo";
            this.UsageInfo.ReadOnly = true;
            this.UsageInfo.Size = new System.Drawing.Size(1015, 13);
            this.UsageInfo.TabIndex = 2;
            this.UsageInfo.Text = "user: [$user] computer: [$client] in [$my_root] started at: \"+(get-date -format \"" +
    "[dd/MM/yyyy HH:mm:ss]";
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.button3);
            this.groupBox1.Controls.Add(this.button10);
            this.groupBox1.Controls.Add(this.button9);
            this.groupBox1.Controls.Add(this.button8);
            this.groupBox1.Controls.Add(this.button7);
            this.groupBox1.Controls.Add(this.button6);
            this.groupBox1.Controls.Add(this.button2);
            this.groupBox1.Controls.Add(this.button5);
            this.groupBox1.Controls.Add(this.button1);
            this.groupBox1.Controls.Add(this.button4);
            this.groupBox1.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.groupBox1.Location = new System.Drawing.Point(10, 125);
            this.groupBox1.Margin = new System.Windows.Forms.Padding(5);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(150, 280);
            this.groupBox1.TabIndex = 3;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "single user actions";
            // 
            // groupBox2
            // 
            this.groupBox2.Controls.Add(this.button20);
            this.groupBox2.Controls.Add(this.button19);
            this.groupBox2.Controls.Add(this.button18);
            this.groupBox2.Controls.Add(this.button17);
            this.groupBox2.Controls.Add(this.button16);
            this.groupBox2.Controls.Add(this.button15);
            this.groupBox2.Controls.Add(this.button14);
            this.groupBox2.Controls.Add(this.button13);
            this.groupBox2.Controls.Add(this.button12);
            this.groupBox2.Controls.Add(this.button11);
            this.groupBox2.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.groupBox2.Location = new System.Drawing.Point(10, 410);
            this.groupBox2.Margin = new System.Windows.Forms.Padding(5);
            this.groupBox2.Name = "groupBox2";
            this.groupBox2.Size = new System.Drawing.Size(150, 280);
            this.groupBox2.TabIndex = 4;
            this.groupBox2.TabStop = false;
            this.groupBox2.Text = "tenant actions";
            // 
            // selected_user
            // 
            this.selected_user.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.selected_user.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.selected_user.Font = new System.Drawing.Font("Lucida Console", 9F);
            this.selected_user.Location = new System.Drawing.Point(700, 30);
            this.selected_user.Multiline = true;
            this.selected_user.Name = "selected_user";
            this.selected_user.ReadOnly = true;
            this.selected_user.Size = new System.Drawing.Size(475, 20);
            this.selected_user.TabIndex = 5;
            this.selected_user.Text = "selected user: [ -- no user selected -- ]";
            // 
            // button1
            // 
            this.button1.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button1.Location = new System.Drawing.Point(5, 20);
            this.button1.Name = "button1";
            this.button1.Size = new System.Drawing.Size(140, 25);
            this.button1.TabIndex = 6;
            this.button1.Text = "button1";
            this.button1.UseVisualStyleBackColor = true;
            // 
            // button2
            // 
            this.button2.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button2.Location = new System.Drawing.Point(5, 51);
            this.button2.Name = "button2";
            this.button2.Size = new System.Drawing.Size(140, 25);
            this.button2.TabIndex = 7;
            this.button2.Text = "button2";
            this.button2.UseVisualStyleBackColor = true;
            // 
            // button3
            // 
            this.button3.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button3.Location = new System.Drawing.Point(5, 76);
            this.button3.Name = "button3";
            this.button3.Size = new System.Drawing.Size(140, 25);
            this.button3.TabIndex = 8;
            this.button3.Text = "button3";
            this.button3.UseVisualStyleBackColor = true;
            // 
            // button4
            // 
            this.button4.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button4.Location = new System.Drawing.Point(5, 100);
            this.button4.Name = "button4";
            this.button4.Size = new System.Drawing.Size(140, 25);
            this.button4.TabIndex = 9;
            this.button4.Text = "button4";
            this.button4.UseVisualStyleBackColor = true;
            // 
            // button5
            // 
            this.button5.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button5.Location = new System.Drawing.Point(5, 125);
            this.button5.Name = "button5";
            this.button5.Size = new System.Drawing.Size(140, 25);
            this.button5.TabIndex = 10;
            this.button5.Text = "button5";
            this.button5.UseVisualStyleBackColor = true;
            // 
            // button6
            // 
            this.button6.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button6.Location = new System.Drawing.Point(5, 150);
            this.button6.Name = "button6";
            this.button6.Size = new System.Drawing.Size(140, 25);
            this.button6.TabIndex = 11;
            this.button6.Text = "button6";
            this.button6.UseVisualStyleBackColor = true;
            // 
            // button7
            // 
            this.button7.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button7.Location = new System.Drawing.Point(5, 175);
            this.button7.Name = "button7";
            this.button7.Size = new System.Drawing.Size(140, 25);
            this.button7.TabIndex = 12;
            this.button7.Text = "button7";
            this.button7.UseVisualStyleBackColor = true;
            // 
            // button8
            // 
            this.button8.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button8.Location = new System.Drawing.Point(5, 200);
            this.button8.Name = "button8";
            this.button8.Size = new System.Drawing.Size(140, 25);
            this.button8.TabIndex = 13;
            this.button8.Text = "button8";
            this.button8.UseVisualStyleBackColor = true;
            // 
            // button9
            // 
            this.button9.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button9.Location = new System.Drawing.Point(5, 225);
            this.button9.Name = "button9";
            this.button9.Size = new System.Drawing.Size(140, 25);
            this.button9.TabIndex = 14;
            this.button9.Text = "button9";
            this.button9.UseVisualStyleBackColor = true;
            // 
            // button10
            // 
            this.button10.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button10.Location = new System.Drawing.Point(5, 250);
            this.button10.Name = "button10";
            this.button10.Size = new System.Drawing.Size(140, 25);
            this.button10.TabIndex = 15;
            this.button10.Text = "button10";
            this.button10.UseVisualStyleBackColor = true;
            // 
            // button11
            // 
            this.button11.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button11.Location = new System.Drawing.Point(5, 20);
            this.button11.Name = "button11";
            this.button11.Size = new System.Drawing.Size(140, 25);
            this.button11.TabIndex = 16;
            this.button11.Text = "button11";
            this.button11.UseVisualStyleBackColor = true;
            // 
            // button12
            // 
            this.button12.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button12.Location = new System.Drawing.Point(5, 45);
            this.button12.Name = "button12";
            this.button12.Size = new System.Drawing.Size(140, 25);
            this.button12.TabIndex = 17;
            this.button12.Text = "button12";
            this.button12.UseVisualStyleBackColor = true;
            // 
            // button13
            // 
            this.button13.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button13.Location = new System.Drawing.Point(5, 70);
            this.button13.Name = "button13";
            this.button13.Size = new System.Drawing.Size(140, 25);
            this.button13.TabIndex = 18;
            this.button13.Text = "button13";
            this.button13.UseVisualStyleBackColor = true;
            // 
            // button14
            // 
            this.button14.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button14.Location = new System.Drawing.Point(5, 95);
            this.button14.Name = "button14";
            this.button14.Size = new System.Drawing.Size(140, 25);
            this.button14.TabIndex = 19;
            this.button14.Text = "button14";
            this.button14.UseVisualStyleBackColor = true;
            // 
            // button15
            // 
            this.button15.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button15.Location = new System.Drawing.Point(5, 120);
            this.button15.Name = "button15";
            this.button15.Size = new System.Drawing.Size(140, 25);
            this.button15.TabIndex = 20;
            this.button15.Text = "button15";
            this.button15.UseVisualStyleBackColor = true;
            // 
            // button16
            // 
            this.button16.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button16.Location = new System.Drawing.Point(5, 145);
            this.button16.Name = "button16";
            this.button16.Size = new System.Drawing.Size(140, 25);
            this.button16.TabIndex = 21;
            this.button16.Text = "button16";
            this.button16.UseVisualStyleBackColor = true;
            // 
            // button17
            // 
            this.button17.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button17.Location = new System.Drawing.Point(5, 170);
            this.button17.Name = "button17";
            this.button17.Size = new System.Drawing.Size(140, 25);
            this.button17.TabIndex = 22;
            this.button17.Text = "button17";
            this.button17.UseVisualStyleBackColor = true;
            // 
            // button18
            // 
            this.button18.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button18.Location = new System.Drawing.Point(5, 195);
            this.button18.Name = "button18";
            this.button18.Size = new System.Drawing.Size(140, 25);
            this.button18.TabIndex = 23;
            this.button18.Text = "button18";
            this.button18.UseVisualStyleBackColor = true;
            // 
            // button19
            // 
            this.button19.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button19.Location = new System.Drawing.Point(5, 220);
            this.button19.Name = "button19";
            this.button19.Size = new System.Drawing.Size(140, 25);
            this.button19.TabIndex = 24;
            this.button19.Text = "button19";
            this.button19.UseVisualStyleBackColor = true;
            // 
            // button20
            // 
            this.button20.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F);
            this.button20.Location = new System.Drawing.Point(5, 245);
            this.button20.Name = "button20";
            this.button20.Size = new System.Drawing.Size(140, 25);
            this.button20.TabIndex = 25;
            this.button20.Text = "button20";
            this.button20.UseVisualStyleBackColor = true;
            // 
            // ExitButton
            // 
            this.ExitButton.Font = new System.Drawing.Font("Microsoft Sans Serif", 14.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.ExitButton.Location = new System.Drawing.Point(10, 700);
            this.ExitButton.Name = "ExitButton";
            this.ExitButton.Size = new System.Drawing.Size(150, 35);
            this.ExitButton.TabIndex = 26;
            this.ExitButton.Text = "EXIT";
            this.ExitButton.UseVisualStyleBackColor = true;
            // 
            // progressBar1
            // 
            this.progressBar1.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left)));
            this.progressBar1.Location = new System.Drawing.Point(175, 735);
            this.progressBar1.Name = "progressBar1";
            this.progressBar1.Size = new System.Drawing.Size(1000, 20);
            this.progressBar1.TabIndex = 27;
            // 
            // statusfield
            // 
            this.statusfield.Location = new System.Drawing.Point(15, 735);
            this.statusfield.Name = "statusfield";
            this.statusfield.Size = new System.Drawing.Size(140, 20);
            this.statusfield.TabIndex = 28;
            this.statusfield.Text = "status";
            this.statusfield.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // textBox1
            // 
            this.textBox1.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(255)))), ((int)(((byte)(255)))), ((int)(((byte)(220)))));
            this.textBox1.Font = new System.Drawing.Font("Lucida Console", 9F);
            this.textBox1.Location = new System.Drawing.Point(175, 130);
            this.textBox1.Multiline = true;
            this.textBox1.Name = "textBox1";
            this.textBox1.ReadOnly = true;
            this.textBox1.Size = new System.Drawing.Size(1000, 600);
            this.textBox1.TabIndex = 29;
            // 
            // userinputBox
            // 
            this.userinputBox.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.userinputBox.Location = new System.Drawing.Point(660, 20);
            this.userinputBox.Name = "userinputBox";
            this.userinputBox.Size = new System.Drawing.Size(515, 23);
            this.userinputBox.TabIndex = 30;
            // 
            // Main
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(8F, 16F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1180, 792);
            this.Controls.Add(this.userinputBox);
            this.Controls.Add(this.textBox1);
            this.Controls.Add(this.statusfield);
            this.Controls.Add(this.progressBar1);
            this.Controls.Add(this.ExitButton);
            this.Controls.Add(this.selected_user);
            this.Controls.Add(this.groupBox2);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.UsageInfo);
            this.Controls.Add(this.Title);
            this.Controls.Add(this.Logo);
            this.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.Fixed3D;
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.Margin = new System.Windows.Forms.Padding(4);
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "Main";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "P2V Usermanagement";
            this.Load += new System.EventHandler(this.Main_Load);
            ((System.ComponentModel.ISupportInitialize)(this.Logo)).EndInit();
            this.groupBox1.ResumeLayout(false);
            this.groupBox2.ResumeLayout(false);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.PictureBox Logo;
        private System.Windows.Forms.Label Title;
        private System.Windows.Forms.TextBox UsageInfo;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.GroupBox groupBox2;
        private System.Windows.Forms.TextBox selected_user;
        private System.Windows.Forms.Button button1;
        private System.Windows.Forms.Button button2;
        private System.Windows.Forms.Button button3;
        private System.Windows.Forms.Button button4;
        private System.Windows.Forms.Button button5;
        private System.Windows.Forms.Button button6;
        private System.Windows.Forms.Button button10;
        private System.Windows.Forms.Button button9;
        private System.Windows.Forms.Button button8;
        private System.Windows.Forms.Button button7;
        private System.Windows.Forms.Button button18;
        private System.Windows.Forms.Button button17;
        private System.Windows.Forms.Button button16;
        private System.Windows.Forms.Button button15;
        private System.Windows.Forms.Button button14;
        private System.Windows.Forms.Button button13;
        private System.Windows.Forms.Button button12;
        private System.Windows.Forms.Button button11;
        private System.Windows.Forms.Button button20;
        private System.Windows.Forms.Button button19;
        private System.Windows.Forms.Button ExitButton;
        private System.Windows.Forms.ProgressBar progressBar1;
        private System.Windows.Forms.Label statusfield;
        private System.Windows.Forms.TextBox textBox1;
        private System.Windows.Forms.TextBox userinputBox;
    }
}

