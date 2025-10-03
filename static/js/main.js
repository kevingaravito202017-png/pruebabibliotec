// Sistema de Biblioteca - Politécnico Colombiano
// JavaScript para interactividad y animaciones

document.addEventListener('DOMContentLoaded', function() {
    // Animaciones on scroll
    initScrollAnimations();

    // Auto-ocultar mensajes flash
    initFlashMessages();

    // Smooth scroll para enlaces internos
    initSmoothScroll();

    // Confirmaciones de eliminación
    initDeleteConfirmations();
});

// Animaciones al hacer scroll
function initScrollAnimations() {
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -100px 0px'
    };

    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate-fade-in');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    // Observar elementos que queremos animar
    const animatedElements = document.querySelectorAll('.book-card, .category-card, .stat-card');
    animatedElements.forEach(el => {
        observer.observe(el);
    });
}

// Auto-ocultar mensajes flash después de 5 segundos
function initFlashMessages() {
    const flashMessages = document.querySelectorAll('.flash-message');
    flashMessages.forEach(message => {
        setTimeout(() => {
            message.style.animation = 'slideIn 0.3s ease reverse';
            setTimeout(() => {
                message.remove();
            }, 300);
        }, 5000);
    });
}

// Smooth scroll para enlaces internos
function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

// Confirmaciones de eliminación mejoradas
function initDeleteConfirmations() {
    const deleteForms = document.querySelectorAll('form[action*="eliminar"]');
    deleteForms.forEach(form => {
        form.addEventListener('submit', function(e) {
            if (!confirm('¿Estás seguro de que deseas eliminar este libro? Esta acción no se puede deshacer.')) {
                e.preventDefault();
            }
        });
    });
}

// Función para preview de imágenes (usada en formularios)
function previewImage(input, previewId) {
    const file = input.files[0];
    if (file) {
        const reader = new FileReader();
        reader.onload = function(e) {
            const preview = document.getElementById(previewId);
            if (preview) {
                preview.src = e.target.result;
                preview.style.display = 'block';
            }
        };
        reader.readAsDataURL(file);
    }
}

// Función para validar formularios
function validateForm(formId) {
    const form = document.getElementById(formId);
    if (!form) return true;

    const requiredFields = form.querySelectorAll('[required]');
    let isValid = true;

    requiredFields.forEach(field => {
        if (!field.value.trim()) {
            isValid = false;
            field.classList.add('error');

            // Crear mensaje de error si no existe
            let errorMsg = field.parentElement.querySelector('.error-message');
            if (!errorMsg) {
                errorMsg = document.createElement('span');
                errorMsg.className = 'error-message';
                errorMsg.textContent = 'Este campo es obligatorio';
                field.parentElement.appendChild(errorMsg);
            }
        } else {
            field.classList.remove('error');
            const errorMsg = field.parentElement.querySelector('.error-message');
            if (errorMsg) {
                errorMsg.remove();
            }
        }
    });

    return isValid;
}

// Función para buscar libros con debounce
let searchTimeout;
function searchBooks(input) {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
        const query = input.value.trim();
        if (query.length >= 3) {
            // Aquí se podría implementar búsqueda AJAX
            console.log('Buscando:', query);
        }
    }, 500);
}

// Función para filtrar por categoría
function filterByCategory(category) {
    const url = new URL(window.location);
    url.searchParams.set('categoria', category);
    window.location = url;
}

// Función para limpiar filtros
function clearFilters() {
    window.location = window.location.pathname;
}

// Agregar efectos hover en cards
document.querySelectorAll('.book-card, .category-card').forEach(card => {
    card.addEventListener('mouseenter', function() {
        this.style.transform = 'translateY(-5px) scale(1.02)';
    });

    card.addEventListener('mouseleave', function() {
        this.style.transform = 'translateY(0) scale(1)';
    });
});

// Función para copiar al portapapeles (útil para referencias)
function copyToClipboard(text) {
    if (navigator.clipboard) {
        navigator.clipboard.writeText(text).then(() => {
            showNotification('Copiado al portapapeles', 'success');
        });
    } else {
        // Fallback para navegadores antiguos
        const textarea = document.createElement('textarea');
        textarea.value = text;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        showNotification('Copiado al portapapeles', 'success');
    }
}

// Función para mostrar notificaciones personalizadas
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `flash-message flash-${type}`;
    notification.innerHTML = `
        <span>${message}</span>
        <button class="close-flash" onclick="this.parentElement.remove()">&times;</button>
    `;

    let container = document.querySelector('.flash-messages');
    if (!container) {
        container = document.createElement('div');
        container.className = 'flash-messages';
        document.body.appendChild(container);
    }

    container.appendChild(notification);

    // Auto-ocultar después de 5 segundos
    setTimeout(() => {
        notification.style.animation = 'slideIn 0.3s ease reverse';
        setTimeout(() => notification.remove(), 300);
    }, 5000);
}

// Lazy loading para imágenes
if ('IntersectionObserver' in window) {
    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                if (img.dataset.src) {
                    img.src = img.dataset.src;
                    img.removeAttribute('data-src');
                    observer.unobserve(img);
                }
            }
        });
    });

    document.querySelectorAll('img[data-src]').forEach(img => {
        imageObserver.observe(img);
    });
}

// Detectar tema del sistema y aplicar si es necesario (futuro)
function detectSystemTheme() {
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
        // El usuario prefiere modo oscuro
        console.log('Sistema en modo oscuro detectado');
    }
}

// Mejorar accesibilidad con teclado
document.addEventListener('keydown', function(e) {
    // Esc para cerrar modales o mensajes
    if (e.key === 'Escape') {
        document.querySelectorAll('.flash-message').forEach(msg => msg.remove());
    }
});

// Estadísticas de uso (opcional)
function trackPageView() {
    // Aquí se podría implementar tracking de analytics
    console.log('Página vista:', window.location.pathname);
}

trackPageView();

// Exportar funciones para uso global
window.BibliotecaPoli = {
    previewImage,
    validateForm,
    searchBooks,
    filterByCategory,
    clearFilters,
    copyToClipboard,
    showNotification
};
