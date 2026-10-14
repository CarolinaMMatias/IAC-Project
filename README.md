# RISC-V Neural Network Classifier

Projects developed for the **Introdução à Arquitetura de Computadores** (Introduction to Computer Architecture) course at **Instituto Superior Técnico (IST)**.

---

## 🧠 About the Project

Implementation of a handwritten digit classifier (0–9) using a single-layer feedforward neural network in **RISC-V 32-bit Assembly**, culminating in a custom hardware accelerator.

The project is divided into three main phases:

---

## 📂 Projects Breakdown

### 🔹 Project 1 — Basic Assembly Routines
* **`abs`**: Calculates the absolute value of an integer in memory.
* **`relu`**: Applies the Rectified Linear Unit activation function on a vector (replaces negative values with zero).
* **`argmax`**: Finds the index of the largest element in an array (used to select the predicted digit).

### 🔹 Project 2 — Matrix Math & Neural Network Inference
* **`dotproduct`**: Computes the dot product of two integer vectors.
* **`matmul`**: Implements 2D matrix multiplication using row-major order.
* **`read_file`**: Loads pre-trained weights and input digit images using Ripes system calls.
* **`classify`**: Assembles the complete forward-pass pipeline:
  1. $h = \text{ReLU}(m_0 \times \text{input})$
  2. $o = m_1 \times h$
  3. Prediction $= \text{argmax}(o)$

### 🔹 Project 3 — Hardware Accelerator (TPU)
* Design of an 8-bit specialized processor / Tensor Processing Unit (TPU) in **Logisim**.
* Implemented as a sequential state machine to accelerate operations like `abs` and `relu` in hardware.

---

## 💻 Tech Stack & Tools
* **Assembly**: RISC-V (32-bit)
* **Simulators**: [Ripes](https://github.com/mortbopet/Ripes) (RISC-V architecture) & [Logisim](http://www.cburch.com/logisim/) (digital logic)
