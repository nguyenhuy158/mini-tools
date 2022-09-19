using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace miniTools
{
    public partial class Form1 : Form
    {
        string[] files;
        string[] newFile;
        public Form1()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            files = Directory.GetFiles(textBox1.Text, "*.png");

            foreach (var item in files)
            {
                listBox1.Items.Add(Path.GetFileName(item));
                //listBox1.Items.Add(Path.GetDirectoryName(item));
            }

            groupBox2.Enabled = true;
            groupBox1.Enabled = false;
        }

        private void checkBox1_CheckedChanged(object sender, EventArgs e)
        {
        }

        private void checkBox1_CheckStateChanged(object sender, EventArgs e)
        {
            if (checkBox1.Checked)
            {
                numericUpDown1.Enabled = true;
            }
            else
            {
                numericUpDown1.Enabled = false;
            }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            if (checkBox1.Checked)
            {
                listBox1.Items.Clear();
                newFile = new string[files.Length];
                for (int i = 0; i < files.Length; i++)
                {

                    //files[i] = files[i].Remove(0, (int)numericUpDown1.Value);
                    newFile[i] = Path.Combine(textBox1.Text, Path.GetFileName(files[i]).Remove(0, (int)numericUpDown1.Value));

                    listBox1.Items.Add(Path.GetFileName(newFile[i]));
                }

                button3.Enabled = true;
            }
            if (checkBox2.Checked)
            {
                listBox1.Items.Clear();
                newFile = new string[files.Length];
                for (int i = 0; i < files.Length; i++)
                {

                    newFile[i] = Path.Combine(textBox1.Text, Path.GetFileName(files[i]).Replace(textBoxOldCharacter.Text, textBoxNewCharacter.Text));

                    listBox1.Items.Add(Path.GetFileName(newFile[i]));
                }

                button3.Enabled = true;
            }
        }

        private void button3_Click(object sender, EventArgs e)
        {
            progressBar1.Maximum = files.Length;
            for (int i = 0; i < files.Length; i++)
            {
                File.Move(files[i], newFile[i]);
                progressBar1.Increment(1);
            }
            groupBox2.Enabled = false;
            groupBox1.Enabled = true;
        }

        private void checkBox2_CheckStateChanged(object sender, EventArgs e)
        {
            if (checkBox2.Checked)
            {
                textBoxOldCharacter.Enabled = true;
                textBoxNewCharacter.Enabled = true;
            }
            else
            {
                textBoxOldCharacter.Enabled = false;
                textBoxNewCharacter.Enabled = false;
            }
        }
    }
}
