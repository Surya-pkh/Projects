import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Simulate loading products
    setTimeout(() => {
      setProducts([
        { id: 1, name: 'Smartphone', price: '$699', image: '/api/placeholder/200/200' },
        { id: 2, name: 'Laptop', price: '$1299', image: '/api/placeholder/200/200' },
        { id: 3, name: 'Headphones', price: '$199', image: '/api/placeholder/200/200' },
        { id: 4, name: 'Smart Watch', price: '$399', image: '/api/placeholder/200/200' },
        { id: 5, name: 'Tablet', price: '$599', image: '/api/placeholder/200/200' },
        { id: 6, name: 'Camera', price: '$899', image: '/api/placeholder/200/200' },
      ]);
      setLoading(false);
    }, 1000);
  }, []);

  if (loading) {
    return (
      <div className="loading">
        <div className="spinner"></div>
        <p>Loading Trend Products...</p>
      </div>
    );
  }

  return (
    <div className="App">
      <header className="header">
        <div className="container">
          <h1 className="logo">Trend</h1>
          <nav className="nav">
            <a href="#home">Home</a>
            <a href="#products">Products</a>
            <a href="#about">About</a>
            <a href="#contact">Contact</a>
          </nav>
        </div>
      </header>

      <main className="main">
        <section className="hero">
          <div className="container">
            <h2>Welcome to Trend Store</h2>
            <p>Discover the latest trends in technology and fashion</p>
            <button className="cta-button">Shop Now</button>
          </div>
        </section>

        <section className="products" id="products">
          <div className="container">
            <h3>Featured Products</h3>
            <div className="product-grid">
              {products.map(product => (
                <div key={product.id} className="product-card">
                  <img src={product.image} alt={product.name} />
                  <h4>{product.name}</h4>
                  <p className="price">{product.price}</p>
                  <button className="add-to-cart">Add to Cart</button>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="stats">
          <div className="container">
            <div className="stat-item">
              <h4>Environment</h4>
              <p>{process.env.NODE_ENV || 'production'}</p>
            </div>
            <div className="stat-item">
              <h4>Version</h4>
              <p>v1.0.0</p>
            </div>
            <div className="stat-item">
              <h4>Build</h4>
              <p>{new Date().toISOString().split('T')[0]}</p>
            </div>
          </div>
        </section>
      </main>

      <footer className="footer">
        <div className="container">
          <p>&copy; 2025 Trend Store. All rights reserved.</p>
          <p>Deployed on Kubernetes with ❤️</p>
        </div>
      </footer>
    </div>
  );
}

export default App;
